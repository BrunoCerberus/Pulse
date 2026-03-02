import EntropyCore
import UIKit
import UserNotifications

/// Live implementation of `NotificationService` using `UNUserNotificationCenter`
/// and `UIApplication` for remote notification registration.
@MainActor
final class LiveNotificationService: NotificationService {
    static let shared = LiveNotificationService()

    private let defaults: UserDefaults

    private enum Keys {
        static let deviceToken = "pulse.deviceToken"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func authorizationStatus() async -> NotificationAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined: return .notDetermined
        case .authorized: return .authorized
        case .denied: return .denied
        case .provisional: return .provisional
        case .ephemeral: return .authorized
        @unknown default: return .notDetermined
        }
    }

    func requestAuthorization() async throws -> Bool {
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]
        let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: options)
        if granted {
            await registerForRemoteNotifications()
        }
        return granted
    }

    func registerForRemoteNotifications() async {
        UIApplication.shared.registerForRemoteNotifications()
    }

    func unregisterForRemoteNotifications() async {
        UIApplication.shared.unregisterForRemoteNotifications()
    }

    func storeDeviceToken(_ token: Data) {
        let hex = token.map { String(format: "%02.2hhx", $0) }.joined()
        defaults.set(hex, forKey: Keys.deviceToken)
        Logger.shared.network("Device token stored", level: .debug)
    }

    var storedDeviceToken: String? {
        defaults.string(forKey: Keys.deviceToken)
    }
}
