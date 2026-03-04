import Foundation

final class MockAnalyticsService: AnalyticsService {
    private(set) var loggedEvents: [AnalyticsEvent] = []
    private(set) var recordedErrors: [(error: Error, userInfo: [String: Any]?)] = []
    private(set) var currentUserID: String?

    func logEvent(_ event: AnalyticsEvent) {
        loggedEvents.append(event)
    }

    func setUserID(_ userID: String?) {
        currentUserID = userID
    }

    func recordError(_ error: Error, userInfo: [String: Any]?) {
        recordedErrors.append((error: error, userInfo: userInfo))
    }

    func reset() {
        loggedEvents.removeAll()
        recordedErrors.removeAll()
        currentUserID = nil
    }
}
