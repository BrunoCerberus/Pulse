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
    }

    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            Tab("Home", systemImage: "newspaper", value: .home) {
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

            Tab("For You", systemImage: "heart.text.square", value: .forYou) {
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

            Tab("Categories", systemImage: "square.grid.2x2", value: .categories) {
                NavigationStack(path: $coordinator.categoriesPath) {
                    CategoriesView(
                        router: CategoriesNavigationRouter(coordinator: coordinator),
                        viewModel: coordinator.categoriesViewModel
                    )
                    .navigationDestination(for: Page.self) { page in
                        coordinator.build(page: page)
                    }
                }
            }

            Tab("Bookmarks", systemImage: "bookmark", value: .bookmarks) {
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

            Tab("Search", systemImage: "magnifyingglass", value: .search, role: .search) {
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
        }
        .tabViewStyle(.sidebarAdaptable)
        .preferredColorScheme(themeManager.colorScheme)
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
}

#Preview {
    CoordinatorView(serviceLocator: .preview)
}
