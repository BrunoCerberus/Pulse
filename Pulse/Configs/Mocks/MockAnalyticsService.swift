import Foundation

final class MockAnalyticsService: AnalyticsService {
    private(set) var loggedEvents: [AnalyticsEvent] = []
    private(set) var recordedErrors: [(error: Error, userInfo: [String: Any]?)] = []
    private(set) var loggedMessages: [String] = []
    private(set) var currentUserID: String?
    private(set) var userProperties: [String: String?] = [:]

    func logEvent(_ event: AnalyticsEvent) {
        loggedEvents.append(event)
    }

    func setUserProperty(_ value: String?, forName name: String) {
        userProperties[name] = value
    }

    func setUserID(_ userID: String?) {
        currentUserID = userID
    }

    func recordError(_ error: Error, userInfo: [String: Any]?) {
        recordedErrors.append((error: error, userInfo: userInfo))
    }

    func log(_ message: String) {
        loggedMessages.append(message)
    }

    func reset() {
        loggedEvents.removeAll()
        recordedErrors.removeAll()
        loggedMessages.removeAll()
        currentUserID = nil
        userProperties.removeAll()
    }
}
