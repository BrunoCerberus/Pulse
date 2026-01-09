import SwiftUI

/// Root SwiftUI view that wires the Coordinator into the UI.
///
/// This view hosts a TabView with each tab having its own NavigationStack
/// bound to the coordinator's per-tab NavigationPath. This ensures navigation
/// isolation between tabs while maintaining centralized navigation control.
struct CoordinatorView: View {
    @StateObject private var coordinator: Coordinator
    @StateObject private var themeManager = ThemeManager.shared

    /// Creates the view with an injected ServiceLocator.
    /// - Parameter serviceLocator: Shared dependency resolver for the app
    init(serviceLocator: ServiceLocator) {
        _coordinator = StateObject(wrappedValue: Coordinator(serviceLocator: serviceLocator))
        configureTabBarAppearance()
    }

    var body: some View {
        AnimatedTabView(selection: $coordinator.selectedTab) {
            Tab("Home", systemImage: AppTab.home.symbolImage, value: .home) {
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

            Tab("For You", systemImage: AppTab.forYou.symbolImage, value: .forYou) {
                NavigationStack(path: $coordinator.forYouPath) {
                    ForYouView(
                        router: ForYouNavigationRouter(coordinator: coordinator),
                        viewModel: coordinator.forYouViewModel
                    )
                    .navigationDestination(for: Page.self) { page in
                        coordinator.build(page: page)
                    }
                }
            }

            Tab("Bookmarks", systemImage: AppTab.bookmarks.symbolImage, value: .bookmarks) {
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

            Tab("Search", systemImage: AppTab.search.symbolImage, value: .search, role: .search) {
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
}
