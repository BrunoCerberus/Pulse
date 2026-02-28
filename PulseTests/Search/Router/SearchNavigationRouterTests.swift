import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("SearchNavigationRouter Tests")
@MainActor
struct SearchNavigationRouterTests {
    let serviceLocator: ServiceLocator
    let coordinator: Coordinator
    let sut: SearchNavigationRouter

    init() {
        serviceLocator = TestServiceLocatorFactory.createFullyMocked()
        coordinator = Coordinator(serviceLocator: serviceLocator)
        sut = SearchNavigationRouter(coordinator: coordinator)
    }

    // MARK: - Initialization Tests

    @Test("Router can be initialized with coordinator")
    func routerCanBeInitializedWithCoordinator() {
        _ = SearchNavigationRouter(coordinator: coordinator)
    }

    @Test("Router can be initialized without coordinator")
    func routerCanBeInitializedWithoutCoordinator() {
        _ = SearchNavigationRouter(coordinator: nil)
    }

    // MARK: - Article Detail Navigation Tests

    @Test("Route article detail pushes to coordinator")
    func routeArticleDetailPushesToCoordinator() {
        let article = Article.mockArticles[0]
        coordinator.selectedTab = .search

        sut.route(navigationEvent: .articleDetail(article))

        #expect(coordinator.searchPath.count == 1)
    }

    @Test("Route multiple articles stacks navigation")
    func routeMultipleArticlesStacksNavigation() {
        let article1 = Article.mockArticles[0]
        let article2 = Article.mockArticles[1]
        coordinator.selectedTab = .search

        sut.route(navigationEvent: .articleDetail(article1))
        sut.route(navigationEvent: .articleDetail(article2))

        #expect(coordinator.searchPath.count == 2)
    }

    // MARK: - Nil Coordinator Tests

    @Test("Route does nothing when coordinator is nil")
    func routeDoesNothingWhenCoordinatorIsNil() {
        let router = SearchNavigationRouter(coordinator: nil)
        let article = Article.mockArticles[0]

        // Should not crash
        router.route(navigationEvent: .articleDetail(article))
    }

    // MARK: - Equatable Tests

    @Test("Routers with same coordinator are equal")
    func routersWithSameCoordinatorAreEqual() {
        let router1 = SearchNavigationRouter(coordinator: coordinator)
        let router2 = SearchNavigationRouter(coordinator: coordinator)

        #expect(router1 == router2)
    }

    @Test("Routers with different coordinators are not equal")
    func routersWithDifferentCoordinatorsAreNotEqual() {
        let coordinator2 = Coordinator(serviceLocator: serviceLocator)
        let router1 = SearchNavigationRouter(coordinator: coordinator)
        let router2 = SearchNavigationRouter(coordinator: coordinator2)

        #expect(router1 != router2)
    }

    @Test("Routers with nil coordinators are equal")
    func routersWithNilCoordinatorsAreEqual() {
        let router1 = SearchNavigationRouter(coordinator: nil)
        let router2 = SearchNavigationRouter(coordinator: nil)

        #expect(router1 == router2)
    }
}
