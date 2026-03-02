import EntropyCore
import FirebaseCore
import FirebaseCrashlytics
import GoogleSignIn
import UIKit
import UserNotifications

/**
 * Main application delegate responsible for handling application lifecycle events.
 *
 * This delegate manages the app's initialization and scene configuration.
 * It's the entry point for the application and handles core setup tasks.
 */
@main
final class PulseAppDelegate: UIResponder, UIApplicationDelegate {
    /// Deeplink manager for handling URL schemes
    private let deeplinkManager = DeeplinkManager.shared

    /**
     * Called when the application has finished launching.
     *
     * This is the first method called after the app is launched.
     * Use this method to perform any final initialization of your application.
     *
     * - Parameter application: The singleton app object
     * - Parameter launchOptions: A dictionary indicating the reason the app was launched
     * - Returns: `true` if the app launch was successful, `false` otherwise
     */
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Skip configuration during unit tests to prevent hanging
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else {
            return true
        }

        // Skip Firebase during UI tests (app runs in separate process without GoogleService-Info.plist)
        let isUITesting = ProcessInfo.processInfo.environment["UI_TESTING"] == "1"
        if !isUITesting {
            FirebaseApp.configure()

            // Disable Crashlytics collection in DEBUG builds to avoid polluting dashboard
            #if DEBUG
                Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(false)
            #endif
        }

        configureNotifications(application)
        return true
    }

    /**
     * Handle URL scheme opening for iOS versions prior to iOS 13.
     *
     * This method is called when the app is opened via a custom URL scheme.
     * For iOS 13+, this is handled by the scene delegate.
     *
     * - Parameter application: The singleton app object
     * - Parameter url: The URL that was opened
     * - Parameter options: Additional options for opening the URL
     * - Returns: True if the URL was handled successfully
     */
    @available(iOS, deprecated: 26.0, message: "Use scene-based URL handling instead")
    func application(
        _: UIApplication,
        open url: URL,
        options _: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        // Handle Google Sign-In callback
        if GIDSignIn.sharedInstance.handle(url) {
            return true
        }

        // Handle deeplinks
        deeplinkManager.parse(url: url)
        return true
    }

    /**
     * Called when a new scene session is being created.
     *
     * This method is called when the system is creating a new scene session.
     * Use this method to select a configuration to create the new scene with.
     *
     * - Parameter application: The singleton app object
     * - Parameter connectingSceneSession: The scene session being created
     * - Parameter options: Additional options for the scene connection
     * - Returns: A configuration object for the new scene
     */
    func application(
        _: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options _: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        // Return the default scene configuration
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    private func configureNotifications(_: UIApplication) {
        // Set delegate for foreground presentation and deeplink routing.
        // Actual permission request is deferred until the user explicitly enables
        // notifications in Settings (handled by NotificationService).
        UNUserNotificationCenter.current().delegate = self
    }
}

// MARK: - Foreground Notification Presentation

extension PulseAppDelegate {
    @objc func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent _: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Respect the in-app notification preference (mirrored to UserDefaults by LiveSettingsService)
        let notificationsEnabled = UserDefaults.standard.object(forKey: "pulse.notificationsEnabled") as? Bool ?? true
        if notificationsEnabled {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([])
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension PulseAppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo

        // Parse deeplink from notification payload using extracted parser
        guard let deeplink = NotificationDeeplinkParser.parse(from: userInfo) else {
            Logger.shared.warning("Push notification received without valid deeplink payload", category: "Navigation")
            return
        }

        deeplinkManager.handle(deeplink: deeplink)
    }

    func application(
        _: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // Store token for future backend integration (FCM or custom push server).
        MainActor.assumeIsolated {
            LiveNotificationService.shared.storeDeviceToken(deviceToken)
        }
    }

    func application(
        _: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        Logger.shared.network("Failed to register for notifications: \(error.localizedDescription)", level: .warning)
    }
}
