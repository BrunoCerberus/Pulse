import FirebaseAnalytics
import FirebaseCrashlytics
import Foundation

final class LiveAnalyticsService: AnalyticsService {
    func logEvent(_ event: AnalyticsEvent) {
        // Run parameters through the same recursive PII sanitizer `recordError`
        // uses. Some events carry free-text fields (e.g. `cloudSyncFailed` /
        // `purchaseFailed` `error` strings sourced from `localizedDescription`),
        // which can embed an email or a tokenized URL; without this they'd reach
        // the analytics dashboard unredacted while the parallel `recordError`
        // call redacts them.
        let sanitizedParameters = event.parameters.map { $0.mapValues(Self.sanitize(any:)) }
        Analytics.logEvent(event.name, parameters: sanitizedParameters)
        // Also log as Crashlytics breadcrumb for crash context
        Crashlytics.crashlytics().log("Event: \(event.name)")
    }

    func setUserID(_ userID: String?) {
        // Sanitize the user ID before forwarding to Firebase / Crashlytics.
        // While current callers pass Firebase UIDs (which are safe), any future
        // caller that accidentally passes a human-identifiable value would be a
        // direct PII leak. Apply the same email / URL redaction that `logEvent`
        // and `recordError` use.  After sanitization, an empty result is mapped
        // to nil so we don't send a blank user ID string.  (Firebase treats `""`
        // and `nil` differently — nil clears the ID.)
        let safeID = userID.map { Self.sanitize($0) } ?? ""
        Analytics.setUserID(safeID.isEmpty ? nil : safeID)
        Crashlytics.crashlytics().setUserID(safeID.isEmpty ? nil : safeID)
    }

    func recordError(_ error: Error, userInfo: [String: Any]?) {
        let sanitizedInfo = Self.buildSanitizedUserInfo(error: error, userInfo: userInfo)
        Crashlytics.crashlytics().record(error: error, userInfo: sanitizedInfo)
    }

    /// Enriches `userInfo` with the error's `domain` / `code` / sanitized
    /// `localizedDescription` and recursively sanitizes the whole dictionary.
    /// Pulled out of `recordError` so unit tests can verify the redaction +
    /// enrichment behaviour without mocking the Crashlytics singleton.
    static func buildSanitizedUserInfo(
        error: Error,
        userInfo: [String: Any]?
    ) -> [String: Any] {
        let nsError = error as NSError
        var enrichedInfo = userInfo ?? [:]
        enrichedInfo["domain"] = nsError.domain
        enrichedInfo["code"] = nsError.code
        // Wrap the localized description through the sanitizer too — Firebase
        // SDK errors sometimes embed the user's email, the request URL with
        // query params, or other PII directly in the message.
        enrichedInfo["localizedDescription"] = sanitize(any: nsError.localizedDescription)
        // Recursive sanitization handles nested dictionaries / arrays that
        // a flat `mapValues` would have skipped over.
        return enrichedInfo.mapValues(sanitize(any:))
    }

    /// Recursively redacts potential PII (emails, URL query strings) from any
    /// value type Crashlytics might serialize. Walks dictionaries and arrays;
    /// for unrecognized types returns the value untouched.
    ///
    /// Internal (not `private`) so unit tests can exercise the redaction logic
    /// directly without round-tripping through the real Crashlytics SDK.
    static func sanitize(any value: Any) -> Any {
        switch value {
        case let string as String:
            return sanitize(string)
        case let dict as [String: Any]:
            return dict.mapValues(sanitize(any:))
        case let array as [Any]:
            return array.map(sanitize(any:))
        case let nsArray as NSArray:
            return nsArray.map { sanitize(any: $0) }
        case let nsDict as NSDictionary:
            var result: [String: Any] = [:]
            for (key, value) in nsDict {
                guard let stringKey = key as? String else { continue }
                result[stringKey] = sanitize(any: value)
            }
            return result
        default:
            return value
        }
    }

    /// Redacts potential PII patterns (emails, URLs with tokens) from error context.
    static func sanitize(_ value: String) -> String {
        var result = value
        // Redact email addresses
        let emailPattern = /[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/
        result = result.replacing(emailPattern, with: "[REDACTED_EMAIL]")
        // Redact URL query parameters (may contain tokens/keys)
        let queryPattern = /\?[^\s]+/
        result = result.replacing(queryPattern, with: "?[REDACTED_PARAMS]")
        return result
    }
}
