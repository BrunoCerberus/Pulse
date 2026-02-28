import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("HomeNavigationRouter Tests")
@MainActor
struct HomeNavigationRouterTests {
    let serviceLocator: ServiceLocator
    let coordinator: Coordinator
    let sut: HomeNavigationRouter

    init() {
        serviceLocator = TestServiceLocatorFactory.createFullyMocked()
        coordinator = Coordinator(serviceLocator: serviceLocator)
        sut = HomeNavigationRouter(coordinator: coordinator)
    }

    // MARK: - Initialization Tests

    @Test("Router can be initialized with coordinator")
    func routerCanBeInitializedWithCoordinator() {
        _ = HomeNavigationRouter(coordinator: coordinator)
    }

    @Test("Router can be initialized without coordinator")
    func routerCanBeInitializedWithoutCoordinator() {
        _ = HomeNavigationRouter(coordinator: nil)
    }

    // MARK: - Article Detail Navigation Tests

    @Test("Route article detail pushes to coordinator")
    func routeArticleDetailPushesToCoordinator() {
        let article = Article.mockArticles[0]
        coordinator.selectedTab = .home

        sut.route(navigationEvent: .articleDetail(article))

        #expect(coordinator.homePath.count == 1)
    }

    @Test("Route article detail with different articles")
    func routeArticleDetailWithDifferentArticles() {
        let article1 = Article.mockArticles[0]
        let article2 = Article.mockArticles[1]
        coordinator.selectedTab = .home

        sut.route(navigationEvent: .articleDetail(article1))
        sut.route(navigationEvent: .articleDetail(article2))

        #expect(coordinator.homePath.count == 2)
    }

    // MARK: - Settings Navigation Tests

    @Test("Route settings pushes to coordinator")
    func routeSettingsPushesToCoordinator() {
        coordinator.selectedTab = .home

        sut.route(navigationEvent: .settings)

        #expect(coordinator.homePath.count == 1)
    }

    // MARK: - Nil Coordinator Tests

    @Test("Route does nothing when coordinator is nil")
    func routeDoesNothingWhenCoordinatorIsNil() {
        let router = HomeNavigationRouter(coordinator: nil)
        let article = Article.mockArticles[0]

        // Should not crash
        router.route(navigationEvent: .articleDetail(article))
        router.route(navigationEvent: .settings)
    }

    // MARK: - Equatable Tests

    @Test("Routers with same coordinator are equal")
    func routersWithSameCoordinatorAreEqual() {
        let router1 = HomeNavigationRouter(coordinator: coordinator)
        let router2 = HomeNavigationRouter(coordinator: coordinator)

        #expect(router1 == router2)
    }

    @Test("Routers with different coordinators are not equal")
    func routersWithDifferentCoordinatorsAreNotEqual() {
        let coordinator2 = Coordinator(serviceLocator: serviceLocator)
        let router1 = HomeNavigationRouter(coordinator: coordinator)
        let router2 = HomeNavigationRouter(coordinator: coordinator2)

        #expect(router1 != router2)
    }

    @Test("Routers with nil coordinators are equal")
    func routersWithNilCoordinatorsAreEqual() {
        let router1 = HomeNavigationRouter(coordinator: nil)
        let router2 = HomeNavigationRouter(coordinator: nil)

        #expect(router1 == router2)
    }
}
