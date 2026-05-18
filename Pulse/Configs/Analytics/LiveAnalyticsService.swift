import FirebaseAnalytics
import FirebaseCrashlytics
import Foundation

final class LiveAnalyticsService: AnalyticsService {
    func logEvent(_ event: AnalyticsEvent) {
        Analytics.logEvent(event.name, parameters: event.parameters)
        // Also log as Crashlytics breadcrumb for crash context
        Crashlytics.crashlytics().log("Event: \(event.name)")
    }

    func setUserID(_ userID: String?) {
        Analytics.setUserID(userID)
        Crashlytics.crashlytics().setUserID(userID ?? "")
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
