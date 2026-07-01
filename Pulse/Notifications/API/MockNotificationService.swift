import Foundation

/// Mock implementation of `NotificationService` for testing and Xcode Previews.
@MainActor
final class MockNotificationService: NotificationService {
    var authorizationStatusResult: NotificationAuthorizationStatus = .notDetermined
    var requestAuthorizationResult: Result<Bool, Error> = .success(true)
    var requestAuthorizationCallCount = 0
    var registerCallCount = 0
    var unregisterCallCount = 0
    private(set) var storedDeviceToken: String?
    private(set) var scheduleMorningBriefingCallCount = 0
    private(set) var lastScheduledMorningBriefingTime: (hour: Int, minute: Int)?
    private(set) var cancelMorningBriefingCallCount = 0

    func authorizationStatus() async -> NotificationAuthorizationStatus {
        authorizationStatusResult
    }

    func requestAuthorization() async throws -> Bool {
        requestAuthorizationCallCount += 1
        return try requestAuthorizationResult.get()
    }

    func registerForRemoteNotifications() async {
        registerCallCount += 1
    }

    func unregisterForRemoteNotifications() async {
        unregisterCallCount += 1
    }

    func storeDeviceToken(_ token: Data) {
        storedDeviceToken = token.map { String(format: "%02.2hhx", $0) }.joined()
    }

    func scheduleMorningBriefingNotification(hour: Int, minute: Int) async {
        scheduleMorningBriefingCallCount += 1
        lastScheduledMorningBriefingTime = (hour, minute)
    }

    func cancelMorningBriefingNotification() {
        cancelMorningBriefingCallCount += 1
        lastScheduledMorningBriefingTime = nil
    }
}
