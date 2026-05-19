import EntropyCore
import UIKit
import UserNotifications

/// Live implementation of `NotificationService` using `UNUserNotificationCenter`
/// and `UIApplication` for remote notification registration.
@MainActor
final class LiveNotificationService: NotificationService {
    static let shared = LiveNotificationService()

    /// Keychain service identifier for the APNs device token. Wiped on
    /// sign-out / account-deletion via `SignOutCleanup.wipeKeychain(...)`.
    static let keychainService = "com.pulse.notifications"

    private let keychain: KeychainStore
    private let defaults: UserDefaults

    private enum Keys {
        /// Legacy UserDefaults key — kept only for the one-time migration to Keychain.
        static let legacyDeviceTokenDefaults = "pulse.deviceToken"
        /// Keychain key for the APNs device token.
        static let deviceTokenKeychain = "device_token"
    }

    /// Initializer is `internal` (not `private`) so unit tests can build
    /// instances with an `InMemoryKeychainStore` and a suite-scoped
    /// `UserDefaults`. Production code should still go through `.shared`.
    init(
        keychain: KeychainStore = KeychainManager(service: keychainService),
        defaults: UserDefaults = .standard
    ) {
        self.keychain = keychain
        self.defaults = defaults
        migrateDeviceTokenFromUserDefaultsIfNeeded()
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
        do {
            try keychain.save(hex, for: Keys.deviceTokenKeychain)
            Logger.shared.network("Device token stored", level: .debug)
        } catch {
            Logger.shared.network("Failed to store device token in keychain: \(error)", level: .warning)
        }
    }

    var storedDeviceToken: String? {
        try? keychain.retrieve(for: Keys.deviceTokenKeychain)
    }

    /// One-time migration: device tokens used to live in `UserDefaults`. Push
    /// tokens aren't secrets, but UserDefaults inherits file-protection class
    /// `.completeUntilFirstUserAuthentication`, which means an iTunes backup
    /// or a jailbreak read can recover them and use them to send spoofed
    /// notifications. Keychain items get `.complete` protection by default.
    private func migrateDeviceTokenFromUserDefaultsIfNeeded() {
        guard let legacyToken = defaults.string(forKey: Keys.legacyDeviceTokenDefaults) else {
            return
        }
        try? keychain.save(legacyToken, for: Keys.deviceTokenKeychain)
        defaults.removeObject(forKey: Keys.legacyDeviceTokenDefaults)
    }
}
