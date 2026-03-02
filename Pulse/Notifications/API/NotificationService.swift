import Foundation

/// OS-level notification authorization status.
enum NotificationAuthorizationStatus: Equatable {
    case notDetermined
    case authorized
    case denied
    case provisional
}

/// Protocol for managing push notification permissions and registration.
///
/// Separates `UNUserNotificationCenter` interactions from domain logic,
/// enabling testability via `MockNotificationService`.
protocol NotificationService: AnyObject {
    /// Fetches the current OS-level authorization status.
    func authorizationStatus() async -> NotificationAuthorizationStatus

    /// Requests notification authorization from the OS.
    /// - Returns: `true` if the user granted permission.
    func requestAuthorization() async throws -> Bool

    /// Registers the app for remote notifications.
    func registerForRemoteNotifications() async

    /// Unregisters from remote notifications.
    func unregisterForRemoteNotifications() async

    /// Stores the device token for future backend integration.
    func storeDeviceToken(_ token: Data)

    /// Returns the last stored device token as a hex string, if any.
    var storedDeviceToken: String? { get }
}
