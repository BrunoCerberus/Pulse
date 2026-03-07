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
        let nsError = error as NSError
        var enrichedInfo = userInfo ?? [:]
        enrichedInfo["domain"] = nsError.domain
        enrichedInfo["code"] = nsError.code

        // Sanitize values to prevent PII leakage to Crashlytics
        let sanitizedInfo = enrichedInfo.mapValues { value -> Any in
            guard let stringValue = value as? String else { return value }
            return Self.sanitize(stringValue)
        }

        Crashlytics.crashlytics().record(error: error, userInfo: sanitizedInfo)
    }

    /// Redacts potential PII patterns (emails, URLs with tokens) from error context.
    private static func sanitize(_ value: String) -> String {
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
