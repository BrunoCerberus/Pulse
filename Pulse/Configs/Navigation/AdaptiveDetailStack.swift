import SwiftUI

/// Detail column for the regular-width `NavigationSplitView` layout.
///
/// Switches on `coordinator.selectedTab` to render the matching root view
/// inside its own `NavigationStack`, preserving the per-tab `NavigationPath`
/// and `.navigationDestination(for: Page.self)` wiring used on compact width.
struct AdaptiveDetailStack: View {
    @ObservedObject var coordinator: Coordinator

    var body: some View {
        switch coordinator.selectedTab {
        case .home:
            NavigationStack(path: $coordinator.homePath) {
                HomeView(
                    router: HomeNavigationRouter(coordinator: coordinator),
                    viewModel: coordinator.homeViewModel
                )
                .navigationDestination(for: Page.self) { page in
                    coordinator.build(page: page)
                }
            }

        case .media:
            NavigationStack(path: $coordinator.mediaPath) {
                MediaView(
                    router: MediaNavigationRouter(coordinator: coordinator),
                    viewModel: coordinator.mediaViewModel
                )
                .navigationDestination(for: Page.self) { page in
                    coordinator.build(page: page)
                }
            }

        case .feed:
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

        case .bookmarks:
            NavigationStack(path: $coordinator.bookmarksPath) {
                BookmarksView(
                    router: BookmarksNavigationRouter(coordinator: coordinator),
                    viewModel: coordinator.bookmarksViewModel
                )
                .navigationDestination(for: Page.self) { page in
                    coordinator.build(page: page)
                }
            }

        case .search:
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
}
