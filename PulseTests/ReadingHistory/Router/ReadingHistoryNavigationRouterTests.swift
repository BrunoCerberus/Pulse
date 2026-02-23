import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("ReadingHistoryNavigationRouter Tests")
@MainActor
struct ReadingHistoryNavigationRouterTests {
    let serviceLocator: ServiceLocator
    let coordinator: Coordinator
    let sut: ReadingHistoryNavigationRouter

    init() {
        serviceLocator = TestServiceLocatorFactory.createFullyMocked()
        coordinator = Coordinator(serviceLocator: serviceLocator)
        sut = ReadingHistoryNavigationRouter(coordinator: coordinator)
    }

    // MARK: - Article Detail Navigation Tests

    @Test("Route article detail pushes to coordinator")
    func routeArticleDetailPushesToCoordinator() {
        let article = Article.mockArticles[0]
        // Reading history is pushed onto the home tab
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

    // MARK: - Nil Coordinator Tests

    @Test("Route does nothing when coordinator is nil")
    func routeDoesNothingWhenCoordinatorIsNil() {
        let router = ReadingHistoryNavigationRouter(coordinator: nil)
        let article = Article.mockArticles[0]

        // Should not crash
        router.route(navigationEvent: .articleDetail(article))
    }

    // MARK: - Equatable Tests

    @Test("Routers with same coordinator are equal")
    func routersWithSameCoordinatorAreEqual() {
        let router1 = ReadingHistoryNavigationRouter(coordinator: coordinator)
        let router2 = ReadingHistoryNavigationRouter(coordinator: coordinator)

        #expect(router1 == router2)
    }

    @Test("Routers with different coordinators are not equal")
    func routersWithDifferentCoordinatorsAreNotEqual() {
        let coordinator2 = Coordinator(serviceLocator: serviceLocator)
        let router1 = ReadingHistoryNavigationRouter(coordinator: coordinator)
        let router2 = ReadingHistoryNavigationRouter(coordinator: coordinator2)

        #expect(router1 != router2)
    }

    @Test("Routers with nil coordinators are equal")
    func routersWithNilCoordinatorsAreEqual() {
        let router1 = ReadingHistoryNavigationRouter(coordinator: nil)
        let router2 = ReadingHistoryNavigationRouter(coordinator: nil)

        #expect(router1 == router2)
    }

    @Test("Router with coordinator and router with nil are not equal")
    func routerWithCoordinatorAndNilNotEqual() {
        let router1 = ReadingHistoryNavigationRouter(coordinator: coordinator)
        let router2 = ReadingHistoryNavigationRouter(coordinator: nil)

        #expect(router1 != router2)
    }
}
