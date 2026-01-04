import Foundation
@testable import Pulse
import Testing

@Suite("BookmarksNavigationRouter Tests")
@MainActor
struct BookmarksNavigationRouterTests {
    let serviceLocator: ServiceLocator
    let coordinator: Coordinator
    let sut: BookmarksNavigationRouter

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
        sut = BookmarksNavigationRouter(coordinator: coordinator)
    }

    // MARK: - Initialization Tests

    @Test("Router can be initialized with coordinator")
    func routerCanBeInitializedWithCoordinator() {
        let router = BookmarksNavigationRouter(coordinator: coordinator)
        #expect(router != nil)
    }

    @Test("Router can be initialized without coordinator")
    func routerCanBeInitializedWithoutCoordinator() {
        let router = BookmarksNavigationRouter(coordinator: nil)
        #expect(router != nil)
    }

    // MARK: - Article Detail Navigation Tests

    @Test("Route article detail pushes to coordinator")
    func routeArticleDetailPushesToCoordinator() {
        let article = Article.mockArticles[0]
        coordinator.selectedTab = .bookmarks

        sut.route(navigationEvent: .articleDetail(article))

        #expect(coordinator.bookmarksPath.count == 1)
    }

    @Test("Route article detail with different articles")
    func routeArticleDetailWithDifferentArticles() {
        let article1 = Article.mockArticles[0]
        let article2 = Article.mockArticles[1]
        coordinator.selectedTab = .bookmarks

        sut.route(navigationEvent: .articleDetail(article1))
        sut.route(navigationEvent: .articleDetail(article2))

        #expect(coordinator.bookmarksPath.count == 2)
    }

    // MARK: - Nil Coordinator Tests

    @Test("Route does nothing when coordinator is nil")
    func routeDoesNothingWhenCoordinatorIsNil() {
        let router = BookmarksNavigationRouter(coordinator: nil)
        let article = Article.mockArticles[0]

        // Should not crash
        router.route(navigationEvent: .articleDetail(article))
    }

    // MARK: - Equatable Tests

    @Test("Routers with same coordinator are equal")
    func routersWithSameCoordinatorAreEqual() {
        let router1 = BookmarksNavigationRouter(coordinator: coordinator)
        let router2 = BookmarksNavigationRouter(coordinator: coordinator)

        #expect(router1 == router2)
    }

    @Test("Routers with different coordinators are not equal")
    func routersWithDifferentCoordinatorsAreNotEqual() {
        let coordinator2 = Coordinator(serviceLocator: serviceLocator)
        let router1 = BookmarksNavigationRouter(coordinator: coordinator)
        let router2 = BookmarksNavigationRouter(coordinator: coordinator2)

        #expect(router1 != router2)
    }

    @Test("Routers with nil coordinators are equal")
    func routersWithNilCoordinatorsAreEqual() {
        let router1 = BookmarksNavigationRouter(coordinator: nil)
        let router2 = BookmarksNavigationRouter(coordinator: nil)

        #expect(router1 == router2)
    }

    @Test("Router with coordinator and router with nil are not equal")
    func routerWithCoordinatorAndNilNotEqual() {
        let router1 = BookmarksNavigationRouter(coordinator: coordinator)
        let router2 = BookmarksNavigationRouter(coordinator: nil)

        #expect(router1 != router2)
    }
}
