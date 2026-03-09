import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("StoryThreadNavigationRouter Tests")
@MainActor
struct StoryThreadNavigationRouterTests {
    let serviceLocator: ServiceLocator
    let coordinator: Coordinator
    let sut: StoryThreadNavigationRouter

    init() {
        serviceLocator = TestServiceLocatorFactory.createFullyMocked()
        coordinator = Coordinator(serviceLocator: serviceLocator)
        sut = StoryThreadNavigationRouter(coordinator: coordinator)
    }

    // MARK: - Thread Detail Navigation Tests

    @Test("Route thread detail pushes to coordinator")
    func routeThreadDetailPushesToCoordinator() {
        let item = StoryThreadItem(from: StoryThread.sampleThreads[0])
        coordinator.selectedTab = .home

        sut.route(navigationEvent: .threadDetail(item))

        #expect(coordinator.homePath.count == 1)
    }

    @Test("Route multiple thread details pushes multiple pages")
    func routeMultipleThreadDetails() {
        let item1 = StoryThreadItem(from: StoryThread.sampleThreads[0])
        let item2 = StoryThreadItem(from: StoryThread.sampleThreads[1])
        coordinator.selectedTab = .home

        sut.route(navigationEvent: .threadDetail(item1))
        sut.route(navigationEvent: .threadDetail(item2))

        #expect(coordinator.homePath.count == 2)
    }

    @Test("Route article detail pushes to coordinator")
    func routeArticleDetailPushesToCoordinator() {
        let article = Article.mockArticles[0]
        coordinator.selectedTab = .home

        sut.route(navigationEvent: .articleDetail(article))

        #expect(coordinator.homePath.count == 1)
    }

    // MARK: - Nil Coordinator Tests

    @Test("Route does nothing when coordinator is nil")
    func routeDoesNothingWhenCoordinatorIsNil() {
        let router = StoryThreadNavigationRouter(coordinator: nil)
        let item = StoryThreadItem(from: StoryThread.sampleThreads[0])

        // Should not crash
        router.route(navigationEvent: .threadDetail(item))
    }

    @Test("Route article detail does nothing when coordinator is nil")
    func routeArticleDetailDoesNothingWhenCoordinatorIsNil() {
        let router = StoryThreadNavigationRouter(coordinator: nil)
        let article = Article.mockArticles[0]

        // Should not crash
        router.route(navigationEvent: .articleDetail(article))
    }

    // MARK: - Equatable Tests

    @Test("Routers with same coordinator are equal")
    func routersWithSameCoordinatorAreEqual() {
        let router1 = StoryThreadNavigationRouter(coordinator: coordinator)
        let router2 = StoryThreadNavigationRouter(coordinator: coordinator)

        #expect(router1 == router2)
    }

    @Test("Routers with different coordinators are not equal")
    func routersWithDifferentCoordinatorsAreNotEqual() {
        let coordinator2 = Coordinator(serviceLocator: serviceLocator)
        let router1 = StoryThreadNavigationRouter(coordinator: coordinator)
        let router2 = StoryThreadNavigationRouter(coordinator: coordinator2)

        #expect(router1 != router2)
    }

    @Test("Routers with nil coordinators are equal")
    func routersWithNilCoordinatorsAreEqual() {
        let router1 = StoryThreadNavigationRouter(coordinator: nil)
        let router2 = StoryThreadNavigationRouter(coordinator: nil)

        #expect(router1 == router2)
    }

    @Test("Router with coordinator and router with nil are not equal")
    func routerWithCoordinatorAndNilNotEqual() {
        let router1 = StoryThreadNavigationRouter(coordinator: coordinator)
        let router2 = StoryThreadNavigationRouter(coordinator: nil)

        #expect(router1 != router2)
    }
}
