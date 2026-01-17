import FirebaseCore
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

    private func configureNotifications(_ application: UIApplication) {
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { _, _ in }
        application.registerForRemoteNotifications()
    }
}

extension PulseAppDelegate: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent _: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge]
    }

    nonisolated func userNotificationCenter(
        _: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo

        // Parse deeplink from notification payload using extracted parser
        guard let deeplink = NotificationDeeplinkParser.parse(from: userInfo) else {
            Logger.shared.warning("Push notification received without valid deeplink payload", category: "Navigation")
            return
        }

        await MainActor.run {
            self.deeplinkManager.handle(deeplink: deeplink)
        }
    }

    func application(
        _: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        Logger.shared.network("Device Token: \(token)", level: .info)
    }

    func application(
        _: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        Logger.shared.network("Failed to register for notifications: \(error.localizedDescription)", level: .warning)
    }
}
