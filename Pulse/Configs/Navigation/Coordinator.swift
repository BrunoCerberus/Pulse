import EntropyCore
import SwiftUI

/// Protocol for tabs that support animated symbol effects.
protocol AnimatedTabSelectable: CaseIterable, Hashable {
    var symbolImage: String { get }
    var symbolEffect: any DiscreteSymbolEffect & SymbolEffect { get }
}

/// Tab selection enum for the main TabView.
enum AppTab: String, CaseIterable, AnimatedTabSelectable {
    case home
    case media
    case feed
    case bookmarks
    case search

    var symbolImage: String {
        switch self {
        case .home: "newspaper"
        case .media: "play.tv"
        case .feed: "text.document"
        case .bookmarks: "bookmark"
        case .search: "magnifyingglass"
        }
    }

    var symbolEffect: any DiscreteSymbolEffect & SymbolEffect {
        switch self {
        case .home: .bounce
        case .media: .bounce
        case .feed: .bounce
        case .bookmarks: .bounce
        case .search: .bounce
        }
    }
}

/// Central navigation coordinator managing per-tab NavigationPaths and building views.
///
/// This coordinator serves as the single source of truth for all navigation state in the app.
/// Each tab maintains its own independent NavigationPath, ensuring navigation isolation between tabs.
///
/// ## Usage
/// ```swift
/// // Push a page onto the current tab's stack
/// coordinator.push(page: .articleDetail(article))
///
/// // Push a page onto a specific tab's stack
/// coordinator.push(page: .settings, in: .home)
///
/// // Switch tabs and optionally push a page
/// coordinator.switchTab(to: .search)
/// ```
@MainActor
final class Coordinator: ObservableObject {
    // MARK: - Published Properties

    /// Currently selected tab
    @Published var selectedTab: AppTab = .home

    /// Navigation path for the Home tab
    @Published var homePath = NavigationPath()

    /// Navigation path for the Media tab
    @Published var mediaPath = NavigationPath()

    /// Navigation path for the Feed tab
    @Published var feedPath = NavigationPath()

    /// Navigation path for the Bookmarks tab
    @Published var bookmarksPath = NavigationPath()

    /// Navigation path for the Search tab
    @Published var searchPath = NavigationPath()

    // MARK: - Dependencies

    /// Service locator for dependency injection
    let serviceLocator: ServiceLocator

    // MARK: - Lazy ViewModels

    /// Shared HomeViewModel instance
    lazy var homeViewModel: HomeViewModel = .init(serviceLocator: serviceLocator)

    /// Shared MediaViewModel instance
    lazy var mediaViewModel: MediaViewModel = .init(serviceLocator: serviceLocator)

    /// Shared FeedViewModel instance
    lazy var feedViewModel: FeedViewModel = .init(serviceLocator: serviceLocator)

    /// Shared BookmarksViewModel instance
    lazy var bookmarksViewModel: BookmarksViewModel = .init(serviceLocator: serviceLocator)

    /// Shared SearchViewModel instance
    lazy var searchViewModel: SearchViewModel = .init(serviceLocator: serviceLocator)

    /// Shared SettingsViewModel instance
    lazy var settingsViewModel: SettingsViewModel = .init(serviceLocator: serviceLocator)

    // MARK: - Initialization

    /// Creates a coordinator with the given service locator.
    /// - Parameter serviceLocator: The service locator for dependency injection
    init(serviceLocator: ServiceLocator) {
        self.serviceLocator = serviceLocator
    }

    // MARK: - Navigation Actions

    /// Pushes a page onto the navigation stack.
    /// - Parameters:
    ///   - page: The destination page to push
    ///   - tab: The tab to push onto (defaults to current tab)
    func push(page: Page, in tab: AppTab? = nil) {
        let targetTab = tab ?? selectedTab
        switch targetTab {
        case .home:
            homePath.append(page)
        case .media:
            mediaPath.append(page)
        case .feed:
            feedPath.append(page)
        case .bookmarks:
            bookmarksPath.append(page)
        case .search:
            searchPath.append(page)
        }
    }

    /// Pops the top page from the current tab's navigation stack.
    func pop() {
        switch selectedTab {
        case .home:
            if !homePath.isEmpty { homePath.removeLast() }
        case .media:
            if !mediaPath.isEmpty { mediaPath.removeLast() }
        case .feed:
            if !feedPath.isEmpty { feedPath.removeLast() }
        case .bookmarks:
            if !bookmarksPath.isEmpty { bookmarksPath.removeLast() }
        case .search:
            if !searchPath.isEmpty { searchPath.removeLast() }
        }
    }

    /// Pops to the root of the specified tab's navigation stack.
    /// - Parameter tab: The tab to pop to root (defaults to current tab)
    func popToRoot(in tab: AppTab? = nil) {
        let targetTab = tab ?? selectedTab
        switch targetTab {
        case .home:
            homePath = NavigationPath()
        case .media:
            mediaPath = NavigationPath()
        case .feed:
            feedPath = NavigationPath()
        case .bookmarks:
            bookmarksPath = NavigationPath()
        case .search:
            searchPath = NavigationPath()
        }
    }

    /// Switches to a different tab and optionally pops to root.
    /// - Parameters:
    ///   - tab: The tab to switch to
    ///   - popToRoot: Whether to pop to root after switching (defaults to false)
    func switchTab(to tab: AppTab, popToRoot: Bool = false) {
        selectedTab = tab
        if popToRoot {
            self.popToRoot(in: tab)
        }
    }

    // MARK: - View Builder

    /// Builds the view for a given page destination.
    /// - Parameter page: The page to build
    /// - Returns: The corresponding SwiftUI view
    @ViewBuilder
    func build(page: Page) -> some View {
        switch page {
        case let .articleDetail(article):
            ArticleDetailView(article: article, serviceLocator: serviceLocator)

        case let .mediaDetail(article):
            MediaDetailView(article: article, serviceLocator: serviceLocator)

        case .settings:
            SettingsView(serviceLocator: serviceLocator)

        case .readingHistory:
            ReadingHistoryView(
                router: ReadingHistoryNavigationRouter(coordinator: self),
                viewModel: ReadingHistoryViewModel(serviceLocator: serviceLocator)
            )
        }
    }
}
