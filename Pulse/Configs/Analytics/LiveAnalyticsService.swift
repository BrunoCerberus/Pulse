import FirebaseAnalytics
import FirebaseCrashlytics
import Foundation

final class LiveAnalyticsService: AnalyticsService {
    func logEvent(_ event: AnalyticsEvent) {
        Analytics.logEvent(event.name, parameters: event.parameters)
        // Also log as Crashlytics breadcrumb for crash context
        Crashlytics.crashlytics().log("Event: \(event.name)")
    }

    func setUserProperty(_ value: String?, forName name: String) {
        Analytics.setUserProperty(value, forName: name)
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
        Crashlytics.crashlytics().record(error: error, userInfo: enrichedInfo)
    }

    func log(_ message: String) {
        Crashlytics.crashlytics().log(message)
    }
}
