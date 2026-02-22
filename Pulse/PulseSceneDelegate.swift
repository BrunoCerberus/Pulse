import Combine
import EntropyCore
import GoogleSignIn
import SwiftUI
import UIKit

/// Scene delegate managing the app's window, service setup, and navigation.
final class PulseSceneDelegate: UIResponder, UIWindowSceneDelegate {
    /// The main window of the application
    var window: UIWindow?

    /// Service locator for dependency injection
    private let serviceLocator: ServiceLocator = .init()

    /// Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()

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

        // Sync analytics user ID with auth state
        configureAnalyticsUserID()

        // Configure app lock manager with app lock service
        configureAppLockManager()

        // Sync language preference from SwiftData to AppLocalization
        syncLanguagePreference()

        // Preload LLM model in background for faster digest generation
        preloadLLMModelIfPremium()

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

    /// Sync analytics user ID with authentication state changes.
    private func configureAnalyticsUserID() {
        guard let analyticsService = try? serviceLocator.retrieve(AnalyticsService.self) else { return }

        MainActor.assumeIsolated {
            AuthenticationManager.shared.$authState
                .sink { state in
                    switch state {
                    case let .authenticated(user):
                        analyticsService.setUserID(user.uid)
                    case .unauthenticated:
                        analyticsService.setUserID(nil)
                    case .loading:
                        break
                    }
                }
                .store(in: &cancellables)
        }
    }

    private func configureAppLockManager() {
        do {
            let appLockService = try serviceLocator.retrieve(AppLockService.self)
            MainActor.assumeIsolated {
                AppLockManager.shared.configure(with: appLockService)
            }
        } catch {
            Logger.shared.service("Failed to configure AppLockManager: \(error)", level: .warning)
        }
    }

    private func isRunningUITests() -> Bool {
        let environment = ProcessInfo.processInfo.environment
        return environment["UI_TESTING"] == "1" || environment["XCTestConfigurationFilePath"] == "UI"
    }

    private func showMainApp(in window: UIWindow) {
        let rootView = UIHostingController(
            rootView: RootView(serviceLocator: serviceLocator)
        )
        rootView.overrideUserInterfaceStyle = uiUserInterfaceStyle(from: ThemeManager.shared.colorScheme)
        window.rootViewController = rootView
    }

    private func showSplashScreen(in window: UIWindow) {
        let splashView = SplashScreenView { [weak self] in
            self?.transitionToMainApp(in: window)
        }

        let splashViewController = UIHostingController(rootView: splashView)
        splashViewController.overrideUserInterfaceStyle = uiUserInterfaceStyle(from: ThemeManager.shared.colorScheme)
        window.rootViewController = splashViewController
    }

    private func transitionToMainApp(in window: UIWindow) {
        let rootView = UIHostingController(
            rootView: RootView(serviceLocator: serviceLocator)
        )
        rootView.overrideUserInterfaceStyle = uiUserInterfaceStyle(from: ThemeManager.shared.colorScheme)

        // Animate transition from splash to main app, respecting reduce motion preference
        let shouldReduceMotion = UIAccessibility.isReduceMotionEnabled
        if shouldReduceMotion {
            // No animation for reduce motion
            window.rootViewController = rootView
        } else {
            UIView.transition(
                with: window,
                duration: 0.3,
                options: .transitionCrossDissolve,
                animations: {
                    window.rootViewController = rootView
                },
                completion: nil
            )
        }
    }

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
                serviceLocator.register(LLMService.self, instance: MockLLMService())
                serviceLocator.register(SummarizationService.self, instance: MockSummarizationService())
                serviceLocator.register(FeedService.self, instance: MockFeedService.withSampleData())
                serviceLocator.register(MediaService.self, instance: MockMediaService())

                // Check for MOCK_PREMIUM environment variable to control premium status in UI tests
                let isPremium = ProcessInfo.processInfo.environment["MOCK_PREMIUM"] == "1"
                serviceLocator.register(StoreKitService.self, instance: MockStoreKitService(isPremium: isPremium))

                serviceLocator.register(RemoteConfigService.self, instance: MockRemoteConfigService())
                serviceLocator.register(AuthService.self, instance: MockAuthService())
                serviceLocator.register(AppLockService.self, instance: MockAppLockService())
                serviceLocator.register(AnalyticsService.self, instance: MockAnalyticsService())
                let mockOnboarding = MockOnboardingService(hasCompletedOnboarding: true)
                serviceLocator.register(OnboardingService.self, instance: mockOnboarding)

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

    private func registerLiveServices() {
        // Register and configure Remote Config service first
        let remoteConfigService = LiveRemoteConfigService()
        serviceLocator.register(RemoteConfigService.self, instance: remoteConfigService)
        APIKeysProvider.configure(with: remoteConfigService)
        SupabaseConfig.configure(with: remoteConfigService)

        // Fetch Remote Config values (fire-and-forget, fallbacks work until ready)
        fetchRemoteConfig(remoteConfigService)

        // Register base services first
        let storageService = LiveStorageService()
        serviceLocator.register(StorageService.self, instance: storageService)

        // Network monitor for offline detection
        let networkMonitor = LiveNetworkMonitorService()
        serviceLocator.register(NetworkMonitorService.self, instance: networkMonitor)

        // All Live services use Supabase backend with Guardian API fallback
        // Supabase backend provides RSS-aggregated articles with high-res images and full content
        // Falls back to Guardian API if Supabase is not configured or on error
        serviceLocator.register(
            NewsService.self,
            instance: CachingNewsService(wrapping: LiveNewsService(), networkMonitor: networkMonitor)
        )
        serviceLocator.register(SearchService.self, instance: LiveSearchService())
        serviceLocator.register(
            MediaService.self,
            instance: CachingMediaService(wrapping: LiveMediaService(), networkMonitor: networkMonitor)
        )
        serviceLocator.register(StoreKitService.self, instance: LiveStoreKitService())
        serviceLocator.register(LLMService.self, instance: LiveLLMService())
        serviceLocator.register(SummarizationService.self, instance: LiveSummarizationService())
        serviceLocator.register(FeedService.self, instance: LiveFeedService())

        // Register services that depend on StorageService
        serviceLocator.register(BookmarksService.self, instance: LiveBookmarksService(storageService: storageService))
        serviceLocator.register(SettingsService.self, instance: LiveSettingsService(storageService: storageService))

        // Register authentication service
        serviceLocator.register(AuthService.self, instance: LiveAuthService())

        // Register app lock service
        serviceLocator.register(AppLockService.self, instance: LiveAppLockService())

        // Register analytics service
        serviceLocator.register(AnalyticsService.self, instance: LiveAnalyticsService())

        // Register onboarding service
        serviceLocator.register(OnboardingService.self, instance: LiveOnboardingService())
    }

    private func syncLanguagePreference() {
        Task { [serviceLocator] in
            do {
                let storageService = try serviceLocator.retrieve(StorageService.self)
                let preferences = try await storageService.fetchUserPreferences()
                let language = preferences?.preferredLanguage ?? (Locale.current.language.languageCode?.identifier ?? "en")
                await MainActor.run {
                    AppLocalization.shared.updateLanguage(language)
                }
            } catch {
                Logger.shared.service("Language preference sync failed: \(error)", level: .debug)
            }
        }
    }

    private func preloadLLMModelIfPremium() {
        Task.detached(priority: .utility) { [serviceLocator] in
            do {
                // Check if user is premium before preloading
                let storeKitService = try serviceLocator.retrieve(StoreKitService.self)
                guard storeKitService.isPremium else {
                    Logger.shared.service("Skipping LLM preload - not premium user")
                    return
                }

                // Preload the model in background
                let llmService = try serviceLocator.retrieve(LLMService.self)
                try await llmService.loadModel()
                Logger.shared.service("LLM model preloaded successfully")
            } catch {
                // Preload failure is non-critical - model will load on-demand
                Logger.shared.service("LLM preload skipped: \(error)", level: .debug)
            }
        }
    }

    private func fetchRemoteConfig(_ service: RemoteConfigService) {
        Task {
            do {
                try await service.fetchAndActivate()
            } catch {
                Logger.shared.service("Remote Config fetch failed: \(error)", level: .warning)
            }
        }
    }

    func sceneDidBecomeActive(_: UIScene) {
        MainActor.assumeIsolated {
            AppLockManager.shared.handleSceneDidBecomeActive()
        }
    }

    func sceneDidEnterBackground(_: UIScene) {
        MainActor.assumeIsolated {
            AppLockManager.shared.handleSceneDidEnterBackground()
        }
    }

    func scene(_: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }

        // Handle Google Sign-In callback
        if GIDSignIn.sharedInstance.handle(url) {
            return
        }

        handleDeeplink(url)
    }

    func scene(_: UIScene, continue userActivity: NSUserActivity) {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL
        else {
            return
        }

        handleDeeplink(url)
    }

    private func handleDeeplink(_ url: URL) {
        DeeplinkManager.shared.parse(url: url)
    }

    private func uiUserInterfaceStyle(from colorScheme: ColorScheme?) -> UIUserInterfaceStyle {
        switch colorScheme {
        case .dark:
            return .dark
        case .light:
            return .light
        case .none:
            return .unspecified
        @unknown default:
            return .unspecified
        }
    }
}
