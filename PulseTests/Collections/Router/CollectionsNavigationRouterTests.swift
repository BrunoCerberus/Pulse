import EntropyCore
import Foundation
@testable import Pulse
import Testing

/// Tests for CollectionsNavigationRouter covering:
/// - Article detail navigation
/// - Nil coordinator safety
/// - Equatable conformance
@Suite("CollectionsNavigationRouter Tests")
@MainActor
struct CollectionsNavigationRouterTests {
    let serviceLocator: ServiceLocator
    let coordinator: Coordinator
    let sut: CollectionsNavigationRouter

    init() {
        serviceLocator = TestServiceLocatorFactory.createFullyMocked()
        serviceLocator.register(CollectionsService.self, instance: MockCollectionsService())
        coordinator = Coordinator(serviceLocator: serviceLocator)
        sut = CollectionsNavigationRouter(coordinator: coordinator)
    }

    // MARK: - Article Detail Navigation Tests

    @Test("Route article detail pushes to coordinator")
    func routeArticleDetailPushesToCoordinator() {
        let article = Article.mockArticles[0]
        coordinator.selectedTab = .collections

        sut.route(navigationEvent: .articleDetail(article))

        #expect(coordinator.collectionsPath.count == 1)
    }

    @Test("Route article detail with different articles")
    func routeArticleDetailWithDifferentArticles() {
        let article1 = Article.mockArticles[0]
        let article2 = Article.mockArticles[1]
        coordinator.selectedTab = .collections

        sut.route(navigationEvent: .articleDetail(article1))
        sut.route(navigationEvent: .articleDetail(article2))

        #expect(coordinator.collectionsPath.count == 2)
    }

    // MARK: - Collection Detail Navigation Tests

    @Test("Route collection detail pushes to coordinator")
    func routeCollectionDetailPushesToCoordinator() {
        let collection = Collection.sampleFeatured.first!
        coordinator.selectedTab = .collections

        sut.route(navigationEvent: .collectionDetail(collection))

        #expect(coordinator.collectionsPath.count == 1)
    }

    // MARK: - Nil Coordinator Tests

    @Test("Route does nothing when coordinator is nil")
    func routeDoesNothingWhenCoordinatorIsNil() {
        let router = CollectionsNavigationRouter(coordinator: nil)
        let article = Article.mockArticles[0]
        let collection = Collection.sampleFeatured.first!

        // Should not crash
        router.route(navigationEvent: .articleDetail(article))
        router.route(navigationEvent: .collectionDetail(collection))
    }

    // MARK: - Equatable Tests

    @Test("Routers with same coordinator are equal")
    func routersWithSameCoordinatorAreEqual() {
        let router1 = CollectionsNavigationRouter(coordinator: coordinator)
        let router2 = CollectionsNavigationRouter(coordinator: coordinator)

        #expect(router1 == router2)
    }

    @Test("Routers with different coordinators are not equal")
    func routersWithDifferentCoordinatorsAreNotEqual() {
        let coordinator2 = Coordinator(serviceLocator: serviceLocator)
        let router1 = CollectionsNavigationRouter(coordinator: coordinator)
        let router2 = CollectionsNavigationRouter(coordinator: coordinator2)

        #expect(router1 != router2)
    }

    @Test("Routers with nil coordinators are equal")
    func routersWithNilCoordinatorsAreEqual() {
        let router1 = CollectionsNavigationRouter(coordinator: nil)
        let router2 = CollectionsNavigationRouter(coordinator: nil)

        #expect(router1 == router2)
    }

    @Test("Router with coordinator and router with nil are not equal")
    func routerWithCoordinatorAndNilNotEqual() {
        let router1 = CollectionsNavigationRouter(coordinator: coordinator)
        let router2 = CollectionsNavigationRouter(coordinator: nil)

        #expect(router1 != router2)
    }
}
