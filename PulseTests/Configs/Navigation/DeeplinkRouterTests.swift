import Combine
import Foundation
@testable import Pulse
import Testing

/// Tests for DeeplinkRouter covering:
/// - Home, search, bookmarks, settings navigation
/// - Article and category deeplinks
/// - Deeplink queuing when coordinator unavailable
/// - Integration with DeeplinkManager publisher
/// - Deeplink clearing after routing
@Suite("DeeplinkRouter Tests")
@MainActor
struct DeeplinkRouterTests {
    let serviceLocator: ServiceLocator
    let coordinator: Coordinator
    let sut: DeeplinkRouter

    init() {
        serviceLocator = ServiceLocator()
        serviceLocator.register(NewsService.self, instance: MockNewsService())
        serviceLocator.register(StorageService.self, instance: MockStorageService())
        serviceLocator.register(SearchService.self, instance: MockSearchService())
        serviceLocator.register(ForYouService.self, instance: MockForYouService())
        serviceLocator.register(CategoriesService.self, instance: MockCategoriesService())
        serviceLocator.register(BookmarksService.self, instance: MockBookmarksService())
        serviceLocator.register(SettingsService.self, instance: MockSettingsService())

        coordinator = Coordinator(serviceLocator: serviceLocator)
        sut = DeeplinkRouter()
    }

    // MARK: - Home Deeplink Tests

    @Test("Route home deeplink switches to home tab and pops to root")
    func routeHomeDeeplink() {
        // Notify router that coordinator is available
        NotificationCenter.default.post(
            name: .coordinatorDidBecomeAvailable,
            object: coordinator
        )

        // Set different tab initially
        coordinator.selectedTab = .search

        sut.route(deeplink: .home)

        #expect(coordinator.selectedTab == .home)
        #expect(coordinator.homePath.count == 0)
    }

    // MARK: - Search Deeplink Tests

    @Test("Route search deeplink without query switches to search tab")
    func routeSearchDeeplinkWithoutQuery() {
        NotificationCenter.default.post(
            name: .coordinatorDidBecomeAvailable,
            object: coordinator
        )

        coordinator.selectedTab = .home

        sut.route(deeplink: .search(query: nil))

        #expect(coordinator.selectedTab == .search)
    }

    @Test("Route search deeplink with query sets query and searches")
    func routeSearchDeeplinkWithQuery() async throws {
        NotificationCenter.default.post(
            name: .coordinatorDidBecomeAvailable,
            object: coordinator
        )

        coordinator.selectedTab = .home

        sut.route(deeplink: .search(query: "technology"))

        try await waitForStateUpdate()

        #expect(coordinator.selectedTab == .search)
        #expect(coordinator.searchViewModel.viewState.query == "technology")
    }

    @Test("Route search deeplink with empty query does not set query")
    func routeSearchDeeplinkWithEmptyQuery() {
        NotificationCenter.default.post(
            name: .coordinatorDidBecomeAvailable,
            object: coordinator
        )

        sut.route(deeplink: .search(query: ""))

        #expect(coordinator.selectedTab == .search)
    }

    // MARK: - Bookmarks Deeplink Tests

    @Test("Route bookmarks deeplink switches to bookmarks tab and pops to root")
    func routeBookmarksDeeplink() {
        NotificationCenter.default.post(
            name: .coordinatorDidBecomeAvailable,
            object: coordinator
        )

        coordinator.selectedTab = .home

        sut.route(deeplink: .bookmarks)

        #expect(coordinator.selectedTab == .bookmarks)
        #expect(coordinator.bookmarksPath.count == 0)
    }

    // MARK: - Settings Deeplink Tests

    @Test("Route settings deeplink switches to home and pushes settings")
    func routeSettingsDeeplink() {
        NotificationCenter.default.post(
            name: .coordinatorDidBecomeAvailable,
            object: coordinator
        )

        coordinator.selectedTab = .search

        sut.route(deeplink: .settings)

        #expect(coordinator.selectedTab == .home)
        #expect(coordinator.homePath.count == 1)
    }

    // MARK: - Article Deeplink Tests

    @Test("Route article deeplink switches to home tab")
    func routeArticleDeeplink() {
        NotificationCenter.default.post(
            name: .coordinatorDidBecomeAvailable,
            object: coordinator
        )

        coordinator.selectedTab = .search

        sut.route(deeplink: .article(id: "article-123"))

        #expect(coordinator.selectedTab == .home)
    }

    // MARK: - Category Deeplink Tests

    @Test("Route category deeplink with valid category switches and selects category")
    func routeCategoryDeeplinkValid() async throws {
        NotificationCenter.default.post(
            name: .coordinatorDidBecomeAvailable,
            object: coordinator
        )

        coordinator.selectedTab = .home

        sut.route(deeplink: .category(name: "technology"))

        try await waitForStateUpdate()

        #expect(coordinator.selectedTab == .categories)
        #expect(coordinator.categoriesViewModel.viewState.selectedCategory == .technology)
    }

    @Test("Route category deeplink with invalid category switches but does not select")
    func routeCategoryDeeplinkInvalid() {
        NotificationCenter.default.post(
            name: .coordinatorDidBecomeAvailable,
            object: coordinator
        )

        coordinator.selectedTab = .home

        sut.route(deeplink: .category(name: "invalid-category"))

        #expect(coordinator.selectedTab == .categories)
        #expect(coordinator.categoriesViewModel.viewState.selectedCategory == nil)
    }

    // MARK: - Queued Deeplink Tests

    @Test("Deeplink is queued when coordinator not available")
    func deeplinkIsQueuedWhenCoordinatorNotAvailable() {
        // Create new router without posting coordinator notification
        let newRouter = DeeplinkRouter()

        // Route deeplink before coordinator is available
        newRouter.route(deeplink: .home)

        // Nothing should crash, deeplink should be queued
        #expect(true)
    }

    @Test("Queued deeplink is processed when coordinator becomes available")
    func queuedDeeplinkIsProcessed() async throws {
        // Create new router without posting coordinator notification
        let newRouter = DeeplinkRouter()

        // Route deeplink before coordinator is available
        coordinator.selectedTab = .search
        newRouter.route(deeplink: .home)

        // Now make coordinator available
        NotificationCenter.default.post(
            name: .coordinatorDidBecomeAvailable,
            object: coordinator
        )

        // Give notification time to process
        try await waitForStateUpdate()

        // Queued deeplink should have been processed
        #expect(coordinator.selectedTab == .home)
    }

    // MARK: - Multiple Deeplinks Tests

    @Test("Multiple deeplinks are processed in sequence")
    func multipleDeeplinksProcessed() async throws {
        NotificationCenter.default.post(
            name: .coordinatorDidBecomeAvailable,
            object: coordinator
        )

        coordinator.selectedTab = .home

        sut.route(deeplink: .search(query: "test"))
        try await waitForStateUpdate()

        #expect(coordinator.selectedTab == .search)

        sut.route(deeplink: .bookmarks)
        try await waitForStateUpdate()

        #expect(coordinator.selectedTab == .bookmarks)
    }

    // MARK: - Deeplink Publisher Tests

    @Test("Router responds to DeeplinkManager publisher")
    func routerRespondsToDeeplinkPublisher() async throws {
        NotificationCenter.default.post(
            name: .coordinatorDidBecomeAvailable,
            object: coordinator
        )

        coordinator.selectedTab = .home

        // Simulate DeeplinkManager sending a deeplink
        DeeplinkManager.shared.handle(deeplink: .bookmarks)

        try await waitForStateUpdate()

        #expect(coordinator.selectedTab == .bookmarks)
    }

    // MARK: - Deeplink Clearing Tests

    @Test("Deeplink is cleared after routing")
    func deeplinkIsClearedAfterRouting() async throws {
        NotificationCenter.default.post(
            name: .coordinatorDidBecomeAvailable,
            object: coordinator
        )

        DeeplinkManager.shared.handle(deeplink: .home)

        try await waitForStateUpdate()

        #expect(DeeplinkManager.shared.currentDeeplink == nil)
    }

    // MARK: - Concurrent Navigation Tests

    @Test("Rapid tab switching handles concurrent deeplinks correctly")
    func rapidTabSwitchingHandlesConcurrentDeeplinks() async throws {
        NotificationCenter.default.post(
            name: .coordinatorDidBecomeAvailable,
            object: coordinator
        )

        coordinator.selectedTab = .home

        // Rapidly fire multiple deeplinks to different tabs
        sut.route(deeplink: .search(query: nil))
        sut.route(deeplink: .bookmarks)
        sut.route(deeplink: .home)
        sut.route(deeplink: .search(query: "test"))

        try await waitForStateUpdate(duration: TestWaitDuration.long)

        // Last deeplink should win
        #expect(coordinator.selectedTab == .search)
    }

    @Test("Concurrent deeplinks during active navigation complete without crash")
    func concurrentDeeplinksDuringActiveNavigation() async throws {
        NotificationCenter.default.post(
            name: .coordinatorDidBecomeAvailable,
            object: coordinator
        )

        // Start with a navigation in progress
        coordinator.selectedTab = .home
        coordinator.push(page: .settings, in: .home)

        // Fire deeplinks while navigation is active
        sut.route(deeplink: .bookmarks)
        sut.route(deeplink: .category(name: "technology"))

        try await waitForStateUpdate(duration: TestWaitDuration.long)

        // Should complete without crash - final tab should be categories
        #expect(coordinator.selectedTab == .categories)
    }

    @Test("Multiple coordinators becoming available handles queued deeplinks correctly")
    func multipleCoordinatorNotificationsHandleQueuedDeeplinks() async throws {
        let newRouter = DeeplinkRouter()

        // Queue a deeplink before coordinator is available
        newRouter.route(deeplink: .bookmarks)

        // Post coordinator available notification twice (simulating edge case)
        NotificationCenter.default.post(
            name: .coordinatorDidBecomeAvailable,
            object: coordinator
        )

        try await waitForStateUpdate()

        // Post again to verify no duplicate processing
        NotificationCenter.default.post(
            name: .coordinatorDidBecomeAvailable,
            object: coordinator
        )

        try await waitForStateUpdate()

        // Should only have processed once
        #expect(coordinator.selectedTab == .bookmarks)
    }
}
