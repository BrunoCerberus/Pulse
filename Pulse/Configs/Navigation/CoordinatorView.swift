import Combine
import EntropyCore
import SwiftUI

/// Root SwiftUI view that wires the Coordinator into the UI.
///
/// This view hosts a TabView with each tab having its own NavigationStack
/// bound to the coordinator's per-tab NavigationPath. This ensures navigation
/// isolation between tabs while maintaining centralized navigation control.
struct CoordinatorView: View {
    @StateObject private var coordinator: Coordinator
    @StateObject private var themeManager = ThemeManager.shared
    @ObservedObject private var appLocalization = AppLocalization.shared
    @State private var isOffline = false

    private let networkMonitor: NetworkMonitorService?

    /// Creates the view with an injected ServiceLocator.
    /// - Parameter serviceLocator: Shared dependency resolver for the app
    init(serviceLocator: ServiceLocator) {
        _coordinator = StateObject(wrappedValue: Coordinator(serviceLocator: serviceLocator))
        networkMonitor = try? serviceLocator.retrieve(NetworkMonitorService.self)
        configureTabBarAppearance()
    }

    var body: some View {
        VStack(spacing: 0) {
            if isOffline {
                OfflineBannerView()
            }

            AnimatedTabView(selection: $coordinator.selectedTab) {
                Tab(appLocalization.localized("tab.home"), systemImage: AppTab.home.symbolImage, value: .home) {
                    NavigationStack(path: $coordinator.homePath) {
                        HomeView(
                            router: HomeNavigationRouter(coordinator: coordinator),
                            viewModel: coordinator.homeViewModel
                        )
                        .navigationDestination(for: Page.self) { page in
                            coordinator.build(page: page)
                        }
                    }
                }

                Tab(appLocalization.localized("tab.media"), systemImage: AppTab.media.symbolImage, value: .media) {
                    NavigationStack(path: $coordinator.mediaPath) {
                        MediaView(
                            router: MediaNavigationRouter(coordinator: coordinator),
                            viewModel: coordinator.mediaViewModel
                        )
                        .navigationDestination(for: Page.self) { page in
                            coordinator.build(page: page)
                        }
                    }
                }

                Tab(appLocalization.localized("tab.feed"), systemImage: AppTab.feed.symbolImage, value: .feed) {
                    NavigationStack(path: $coordinator.feedPath) {
                        FeedView(
                            router: FeedNavigationRouter(coordinator: coordinator),
                            viewModel: coordinator.feedViewModel,
                            serviceLocator: coordinator.serviceLocator
                        )
                        .navigationDestination(for: Page.self) { page in
                            coordinator.build(page: page)
                        }
                    }
                }

                Tab(appLocalization.localized("tab.bookmarks"), systemImage: AppTab.bookmarks.symbolImage, value: .bookmarks) {
                    NavigationStack(path: $coordinator.bookmarksPath) {
                        BookmarksView(
                            router: BookmarksNavigationRouter(coordinator: coordinator),
                            viewModel: coordinator.bookmarksViewModel
                        )
                        .navigationDestination(for: Page.self) { page in
                            coordinator.build(page: page)
                        }
                    }
                }

                Tab(appLocalization.localized("tab.search"), systemImage: AppTab.search.symbolImage, value: .search, role: .search) {
                    NavigationStack(path: $coordinator.searchPath) {
                        SearchView(
                            router: SearchNavigationRouter(coordinator: coordinator),
                            viewModel: coordinator.searchViewModel
                        )
                        .navigationDestination(for: Page.self) { page in
                            coordinator.build(page: page)
                        }
                    }
                }
            } effects: { tab in
                tab.symbolEffect
            }
            .preferredColorScheme(themeManager.colorScheme)
            .onChange(of: coordinator.selectedTab) { _, _ in
                HapticManager.shared.tabChange()
            }
            .onAppear {
                setupDeeplinkRouter()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isOffline)
        .onReceive(
            networkMonitor?.isConnectedPublisher ?? Just(true).eraseToAnyPublisher()
        ) { connected in
            let wasOffline = isOffline
            isOffline = !connected
            if !connected, !wasOffline {
                AccessibilityNotification.Announcement(AppLocalization.shared.localized("accessibility.offline")).post()
            } else if connected, wasOffline {
                AccessibilityNotification.Announcement(AppLocalization.shared.localized("accessibility.online")).post()
            }
        }
    }

    /// Posts a notification to make the coordinator available for deeplink routing.
    private func setupDeeplinkRouter() {
        NotificationCenter.default.post(
            name: .coordinatorDidBecomeAvailable,
            object: coordinator
        )
    }

    /// Configures the tab bar appearance for glass morphism styling.
    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemThinMaterial)
        appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.1)

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

#Preview {
    CoordinatorView(serviceLocator: .preview)
        .preferredColorScheme(.dark)
}
