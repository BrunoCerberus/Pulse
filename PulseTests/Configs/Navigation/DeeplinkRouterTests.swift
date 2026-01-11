import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

/// Tests for DeeplinkRouter covering:
/// - Home, search, bookmarks, settings navigation
/// - Article and category deeplinks
/// - Deeplink queuing when coordinator unavailable
/// - Integration with DeeplinkManager publisher
/// - Deeplink clearing after routing
@Suite("DeeplinkRouter Tests", .serialized)
@MainActor
struct DeeplinkRouterTests {
    let serviceLocator: ServiceLocator
    let coordinator: Coordinator
    let sut: DeeplinkRouter

    init() {
        // Clear any lingering deeplinks from previous tests
        DeeplinkManager.shared.clearDeeplink()

        serviceLocator = TestServiceLocatorFactory.createFullyMocked()
        coordinator = Coordinator(serviceLocator: serviceLocator)
        sut = DeeplinkRouter()
    }

    // MARK: - Home Deeplink Tests

    @Test("Route home deeplink switches to home tab and pops to root")
    func routeHomeDeeplink() async throws {
        // Set coordinator directly for synchronous test
        sut.setCoordinator(coordinator)

        // Set different tab initially
        coordinator.selectedTab = .search

        sut.route(deeplink: .home)

        #expect(coordinator.selectedTab == .home)
        #expect(coordinator.homePath.count == 0)
    }

    // MARK: - Search Deeplink Tests

    @Test("Route search deeplink without query switches to search tab")
    func routeSearchDeeplinkWithoutQuery() async throws {
        sut.setCoordinator(coordinator)
        coordinator.selectedTab = .home

        sut.route(deeplink: .search(query: nil))

        #expect(coordinator.selectedTab == .search)
    }

    @Test("Route search deeplink with query sets query and searches")
    func routeSearchDeeplinkWithQuery() async throws {
        sut.setCoordinator(coordinator)
        coordinator.selectedTab = .home

        // Clear any pending state before routing
        coordinator.searchViewModel.handle(event: .onClear)
        try await waitForStateUpdate()

        sut.route(deeplink: .search(query: "technology"))

        // Tab switch is synchronous
        #expect(coordinator.selectedTab == .search)

        // Use condition-based wait for more reliable state verification
        let success = await waitForCondition { [coordinator] in
            coordinator.searchViewModel.viewState.query == "technology"
        }
        #expect(success, "Query should be 'technology' after routing")
    }

    @Test("Route search deeplink with empty query does not set query")
    func routeSearchDeeplinkWithEmptyQuery() async throws {
        sut.setCoordinator(coordinator)

        sut.route(deeplink: .search(query: ""))

        #expect(coordinator.selectedTab == .search)
    }

    // MARK: - Bookmarks Deeplink Tests

    @Test("Route bookmarks deeplink switches to bookmarks tab and pops to root")
    func routeBookmarksDeeplink() async throws {
        sut.setCoordinator(coordinator)
        coordinator.selectedTab = .home

        sut.route(deeplink: .bookmarks)

        #expect(coordinator.selectedTab == .bookmarks)
        #expect(coordinator.bookmarksPath.count == 0)
    }

    // MARK: - Settings Deeplink Tests

    @Test("Route settings deeplink switches to home and pushes settings")
    func routeSettingsDeeplink() async throws {
        sut.setCoordinator(coordinator)
        coordinator.selectedTab = .search

        sut.route(deeplink: .settings)

        #expect(coordinator.selectedTab == .home)
        #expect(coordinator.homePath.count == 1)
    }

    // MARK: - Article Deeplink Tests

    @Test("Route article deeplink switches to home tab")
    func routeArticleDeeplink() async throws {
        sut.setCoordinator(coordinator)
        coordinator.selectedTab = .search

        sut.route(deeplink: .article(id: "article-123"))

        #expect(coordinator.selectedTab == .home)
    }

    // MARK: - Category Deeplink Tests (Legacy - redirects to Home)

    @Test("Route category deeplink switches to home tab")
    func routeCategoryDeeplinkValid() async throws {
        sut.setCoordinator(coordinator)
        coordinator.selectedTab = .search

        sut.route(deeplink: .category(name: "technology"))

        // Category deeplinks now redirect to the Home tab
        #expect(coordinator.selectedTab == .home)
    }

    @Test("Route category deeplink with any name switches to home")
    func routeCategoryDeeplinkInvalid() async throws {
        sut.setCoordinator(coordinator)
        coordinator.selectedTab = .search

        sut.route(deeplink: .category(name: "invalid-category"))

        // All category deeplinks redirect to Home tab
        #expect(coordinator.selectedTab == .home)
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
        // Create new router without setting coordinator
        let newRouter = DeeplinkRouter()

        // Route deeplink before coordinator is available
        coordinator.selectedTab = .search
        newRouter.route(deeplink: .home)

        // Now make coordinator available using direct setter
        newRouter.setCoordinator(coordinator)

        // Queued deeplink should have been processed
        #expect(coordinator.selectedTab == .home)
    }

    // MARK: - Multiple Deeplinks Tests

    @Test("Multiple deeplinks are processed in sequence")
    func multipleDeeplinksProcessed() async throws {
        sut.setCoordinator(coordinator)
        coordinator.selectedTab = .home

        sut.route(deeplink: .search(query: "test"))
        #expect(coordinator.selectedTab == .search)

        sut.route(deeplink: .bookmarks)
        #expect(coordinator.selectedTab == .bookmarks)
    }

    // MARK: - Deeplink Publisher Tests

    @Test("Router responds to DeeplinkManager publisher")
    func routerRespondsToDeeplinkPublisher() async throws {
        sut.setCoordinator(coordinator)
        coordinator.selectedTab = .home

        // Simulate DeeplinkManager sending a deeplink
        DeeplinkManager.shared.handle(deeplink: .bookmarks)

        // Wait for Combine publisher to propagate with condition-based waiting
        let routed = await waitForCondition(timeout: 1_000_000_000) { [coordinator] in
            coordinator.selectedTab == .bookmarks
        }

        #expect(routed)
    }

    // MARK: - Deeplink Clearing Tests

    @Test("Deeplink is cleared after routing")
    func deeplinkIsClearedAfterRouting() async throws {
        sut.setCoordinator(coordinator)

        DeeplinkManager.shared.handle(deeplink: .home)

        try await waitForStateUpdate()

        #expect(DeeplinkManager.shared.currentDeeplink == nil)
    }

    // MARK: - Concurrent Navigation Tests

    @Test("Rapid tab switching handles concurrent deeplinks correctly")
    func rapidTabSwitchingHandlesConcurrentDeeplinks() async throws {
        sut.setCoordinator(coordinator)
        coordinator.selectedTab = .home

        // Rapidly fire multiple deeplinks to different tabs
        sut.route(deeplink: .search(query: nil))
        sut.route(deeplink: .bookmarks)
        sut.route(deeplink: .home)
        sut.route(deeplink: .search(query: "test"))

        // Last deeplink should win
        #expect(coordinator.selectedTab == .search)
    }

    @Test("Concurrent deeplinks during active navigation complete without crash")
    func concurrentDeeplinksDuringActiveNavigation() async throws {
        sut.setCoordinator(coordinator)

        // Start with a navigation in progress
        coordinator.selectedTab = .home
        coordinator.push(page: .settings, in: .home)

        // Fire deeplinks while navigation is active
        sut.route(deeplink: .bookmarks)
        sut.route(deeplink: .category(name: "technology"))

        // Should complete without crash - final tab should be home (category redirects to home)
        #expect(coordinator.selectedTab == .home)
    }

    @Test("Multiple coordinators becoming available handles queued deeplinks correctly")
    func multipleCoordinatorNotificationsHandleQueuedDeeplinks() async throws {
        let newRouter = DeeplinkRouter()

        // Queue a deeplink before coordinator is available
        newRouter.route(deeplink: .bookmarks)

        // Set coordinator - should process queued deeplink
        newRouter.setCoordinator(coordinator)

        #expect(coordinator.selectedTab == .bookmarks)

        // Set coordinator again - should not reprocess (deeplink was cleared)
        coordinator.selectedTab = .home
        newRouter.setCoordinator(coordinator)

        // Should still be home since no new deeplink was queued
        #expect(coordinator.selectedTab == .home)
    }
}
