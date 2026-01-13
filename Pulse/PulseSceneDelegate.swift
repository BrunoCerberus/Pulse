import EntropyCore
import GoogleSignIn
import SwiftUI
import UIKit

/**
 * Scene delegate responsible for managing the app's window and scene lifecycle.
 *
 * This delegate handles the creation and configuration of the app's main window
 * and sets up the root view controller with SwiftUI integration.
 * It also initializes the ServiceLocator with appropriate services based on
 * the current environment (debug/release, test/production).
 *
 * Note: This implementation prevents scene delegate execution during unit tests
 * to avoid conflicts with test environments.
 */
final class PulseSceneDelegate: UIResponder, UIWindowSceneDelegate {
    /// The main window of the application
    var window: UIWindow?

    /// Service locator for dependency injection
    private let serviceLocator: ServiceLocator = .init()

    /// Deeplink router for handling navigation from deeplinks
    private var deeplinkRouter: DeeplinkRouter?

    /// Tracks whether splash screen has been shown
    private var hasSplashBeenShown = false

    /**
     * Called when a scene is being created and connected to the app.
     *
     * This method sets up the main window and configures the root view controller
     * with the app's main content view. It also applies the theme preference
     * and initializes the ServiceLocator with appropriate services.
     *
     * - Parameter scene: The scene being connected
     * - Parameter session: The session that the scene will connect to
     * - Parameter connectionOptions: Additional options for the scene connection
     */
    func scene(
        _ scene: UIScene,
        willConnectTo _: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        // Prevent scene delegate execution during unit tests to avoid conflicts
        guard ProcessInfo.processInfo.environment["IS_RUNNING_UNIT_TESTS"] != "YES" else { return }

        // Initialize services in ServiceLocator
        setupServices()

        // Configure authentication manager with auth service
        configureAuthenticationManager()

        // Initialize deeplink router for coordinator-based navigation
        deeplinkRouter = DeeplinkRouter()

        // Ensure we have a valid window scene
        guard let windowScene = scene as? UIWindowScene else { return }

        // Create and configure the main window
        let window = UIWindow(windowScene: windowScene)
        self.window = window

        // Skip splash screen during UI tests for faster test execution
        if isRunningUITests() {
            showMainApp(in: window)
        } else {
            // Show splash screen first, then transition to main app
            showSplashScreen(in: window)
        }

        // Make the window visible and set it as the key window
        window.makeKeyAndVisible()

        // Handle any deeplinks from launch
        if let urlContext = connectionOptions.urlContexts.first {
            handleDeeplink(urlContext.url)
        }
    }

    /// Configure the AuthenticationManager with the registered AuthService.
    /// Note: This is called from scene(_:willConnectTo:options:) which runs on main thread,
    /// so we use MainActor.assumeIsolated to synchronously configure auth state.
    private func configureAuthenticationManager() {
        do {
            let authService = try serviceLocator.retrieve(AuthService.self)
            MainActor.assumeIsolated {
                AuthenticationManager.shared.configure(with: authService)
            }
        } catch {
            Logger.shared.service("Failed to configure AuthenticationManager: \(error)", level: .warning)
        }
    }

    /**
     * Checks if the app is running in UI test mode.
     *
     * - Returns: `true` if running UI tests, `false` otherwise
     */
    private func isRunningUITests() -> Bool {
        let environment = ProcessInfo.processInfo.environment
        return environment["UI_TESTING"] == "1" || environment["XCTestConfigurationFilePath"] == "UI"
    }

    /**
     * Shows the main app directly without splash screen.
     *
     * Used during UI tests to skip the splash animation.
     *
     * - Parameter window: The main window to display content in
     */
    private func showMainApp(in window: UIWindow) {
        let rootView = UIHostingController(
            rootView: RootView(serviceLocator: serviceLocator)
        )
        rootView.overrideUserInterfaceStyle = ThemeManager.shared.colorScheme == .dark ? .dark : .light
        window.rootViewController = rootView
    }

    /**
     * Shows the splash screen with animation.
     *
     * After the animation completes, transitions to the main app content.
     *
     * - Parameter window: The main window to display content in
     */
    private func showSplashScreen(in window: UIWindow) {
        let splashView = SplashScreenView { [weak self] in
            self?.transitionToMainApp(in: window)
        }

        let splashViewController = UIHostingController(rootView: splashView)
        splashViewController.overrideUserInterfaceStyle = ThemeManager.shared.colorScheme == .dark ? .dark : .light
        window.rootViewController = splashViewController
    }

    /**
     * Transitions from splash screen to the main app content.
     *
     * - Parameter window: The main window to update
     */
    private func transitionToMainApp(in window: UIWindow) {
        let rootView = UIHostingController(
            rootView: RootView(serviceLocator: serviceLocator)
        )
        rootView.overrideUserInterfaceStyle = ThemeManager.shared.colorScheme == .dark ? .dark : .light

        // Animate transition from splash to main app, respecting reduce motion preference
        let shouldReduceMotion = UIAccessibility.isReduceMotionEnabled
        if shouldReduceMotion {
            // No animation for reduce motion
            window.rootViewController = rootView
            hasSplashBeenShown = true
        } else {
            UIView.transition(
                with: window,
                duration: 0.3,
                options: .transitionCrossDissolve,
                animations: {
                    window.rootViewController = rootView
                },
                completion: { [weak self] _ in
                    self?.hasSplashBeenShown = true
                }
            )
        }
    }

    /**
     * Setup services in the ServiceLocator based on current environment.
     *
     * This method registers the appropriate services (real or mock) based on
     * the current build configuration and test environment detection.
     */
    private func setupServices() {
        #if DEBUG
            // Check if running in test environment (unit tests or UI tests)
            // XCTestConfigurationFilePath is set for unit tests
            // UI_TESTING is set by UI tests via launchEnvironment
            let isUnitTesting = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
            let isUITesting = ProcessInfo.processInfo.environment["UI_TESTING"] == "1"

            if isUnitTesting || isUITesting {
                // Use mock services for tests
                serviceLocator.register(StorageService.self, instance: MockStorageService())
                serviceLocator.register(NewsService.self, instance: MockNewsService())
                serviceLocator.register(SearchService.self, instance: MockSearchService())
                serviceLocator.register(BookmarksService.self, instance: MockBookmarksService())
                serviceLocator.register(SettingsService.self, instance: MockSettingsService())
                serviceLocator.register(ForYouService.self, instance: MockForYouService())
                serviceLocator.register(LLMService.self, instance: MockLLMService())
                serviceLocator.register(SummarizationService.self, instance: MockSummarizationService())
                serviceLocator.register(FeedService.self, instance: MockFeedService.withSampleData())
                serviceLocator.register(StoreKitService.self, instance: MockStoreKitService())
                serviceLocator.register(RemoteConfigService.self, instance: MockRemoteConfigService())
                serviceLocator.register(AuthService.self, instance: MockAuthService())

                // Configure APIKeysProvider with mock service
                APIKeysProvider.configure(with: MockRemoteConfigService())
            } else {
                // Use real services for debug builds
                registerLiveServices()
            }
        #else
            // Use real services for release builds
            registerLiveServices()
        #endif
    }

    /**
     * Register all live services for production use.
     *
     * Note: Services that depend on other services (like LiveSettingsService,
     * LiveBookmarksService, LiveForYouService) receive their dependencies
     * directly rather than through ServiceLocator.
     */
    private func registerLiveServices() {
        // Register and configure Remote Config service first
        let remoteConfigService = LiveRemoteConfigService()
        serviceLocator.register(RemoteConfigService.self, instance: remoteConfigService)
        APIKeysProvider.configure(with: remoteConfigService)

        // Fetch Remote Config values (fire-and-forget, fallbacks work until ready)
        fetchRemoteConfig(remoteConfigService)

        // Register base services first
        let storageService = LiveStorageService()
        serviceLocator.register(StorageService.self, instance: storageService)
        serviceLocator.register(NewsService.self, instance: LiveNewsService())
        serviceLocator.register(SearchService.self, instance: LiveSearchService())
        serviceLocator.register(StoreKitService.self, instance: LiveStoreKitService())
        serviceLocator.register(LLMService.self, instance: LiveLLMService())
        serviceLocator.register(SummarizationService.self, instance: LiveSummarizationService())
        serviceLocator.register(FeedService.self, instance: LiveFeedService())

        // Register services that depend on StorageService
        serviceLocator.register(BookmarksService.self, instance: LiveBookmarksService(storageService: storageService))
        serviceLocator.register(SettingsService.self, instance: LiveSettingsService(storageService: storageService))
        serviceLocator.register(ForYouService.self, instance: LiveForYouService(storageService: storageService))

        // Register authentication service
        serviceLocator.register(AuthService.self, instance: LiveAuthService())
    }

    /**
     * Fetch Remote Config values asynchronously.
     *
     * This is fire-and-forget - the app uses fallback API keys until
     * Remote Config values are fetched. Subsequent API calls will use
     * the fetched values from Remote Config.
     */
    private func fetchRemoteConfig(_ service: RemoteConfigService) {
        Task {
            do {
                try await service.fetchAndActivate()
            } catch {
                Logger.shared.service("Remote Config fetch failed: \(error)", level: .warning)
            }
        }
    }

    /**
     * Handle URL opening for the scene.
     *
     * This method is called when the app is opened via a custom URL scheme
     * while the app is running in the foreground.
     *
     * - Parameter scene: The scene that received the URL
     * - Parameter urlContexts: The URL contexts that were opened
     */
    func scene(_: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }

        // Handle Google Sign-In callback
        if GIDSignIn.sharedInstance.handle(url) {
            return
        }

        handleDeeplink(url)
    }

    /**
     * Handle universal links when the app is being activated.
     *
     * This method is called when the app is opened via a universal link.
     * Universal links use HTTPS URLs and are handled differently from custom schemes.
     *
     * - Parameter scene: The scene that received the activity
     * - Parameter userActivity: The user activity containing the universal link
     */
    func scene(_: UIScene, continue userActivity: NSUserActivity) {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL
        else {
            return
        }

        handleDeeplink(url)
    }

    /**
     * Process a deeplink URL.
     *
     * - Parameter url: The URL to process
     */
    private func handleDeeplink(_ url: URL) {
        DeeplinkManager.shared.parse(url: url)
    }
}
