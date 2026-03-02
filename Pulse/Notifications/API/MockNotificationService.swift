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
}
