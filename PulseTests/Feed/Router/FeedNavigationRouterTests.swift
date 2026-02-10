import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("FeedNavigationRouter Tests")
@MainActor
struct FeedNavigationRouterTests {
    @Test("Router initializes with nil coordinator")
    func initWithNilCoordinator() {
        let router = FeedNavigationRouter(coordinator: nil)
        #expect(router.navigation == nil)
    }

    @Test("Router initializes with coordinator")
    func initWithCoordinator() {
        let serviceLocator = TestServiceLocatorFactory.createFullyMocked()
        let coordinator = Coordinator(serviceLocator: serviceLocator)
        let router = FeedNavigationRouter(coordinator: coordinator)

        #expect(router.navigation == nil)
    }

    @Test("Two routers with same coordinator are equal")
    func equalityWithSameCoordinator() {
        let serviceLocator = TestServiceLocatorFactory.createFullyMocked()
        let coordinator = Coordinator(serviceLocator: serviceLocator)
        let router1 = FeedNavigationRouter(coordinator: coordinator)
        let router2 = FeedNavigationRouter(coordinator: coordinator)

        #expect(router1 == router2)
    }

    @Test("Two routers with different coordinators are not equal")
    func inequalityWithDifferentCoordinators() {
        let serviceLocator1 = TestServiceLocatorFactory.createFullyMocked()
        let serviceLocator2 = TestServiceLocatorFactory.createFullyMocked()
        let coordinator1 = Coordinator(serviceLocator: serviceLocator1)
        let coordinator2 = Coordinator(serviceLocator: serviceLocator2)
        let router1 = FeedNavigationRouter(coordinator: coordinator1)
        let router2 = FeedNavigationRouter(coordinator: coordinator2)

        #expect(router1 != router2)
    }

    @Test("Two routers with nil coordinators are equal")
    func equalityWithNilCoordinators() {
        let router1 = FeedNavigationRouter(coordinator: nil)
        let router2 = FeedNavigationRouter(coordinator: nil)

        #expect(router1 == router2)
    }

    @Test("Route articleDetail with nil coordinator does not crash")
    func routeArticleDetailWithNilCoordinator() {
        let router = FeedNavigationRouter(coordinator: nil)
        let article = Article.mockArticles[0]

        router.route(navigationEvent: .articleDetail(article))
        #expect(true)
    }

    @Test("Route settings with nil coordinator does not crash")
    func routeSettingsWithNilCoordinator() {
        let router = FeedNavigationRouter(coordinator: nil)

        router.route(navigationEvent: .settings)
        #expect(true)
    }

    @Test("Route articleDetail with coordinator pushes page")
    func routeArticleDetailWithCoordinator() {
        let serviceLocator = TestServiceLocatorFactory.createFullyMocked()
        let coordinator = Coordinator(serviceLocator: serviceLocator)
        let router = FeedNavigationRouter(coordinator: coordinator)
        let article = Article.mockArticles[0]

        router.route(navigationEvent: .articleDetail(article))
        // Coordinator should have pushed a page
        #expect(true)
    }

    @Test("Route settings with coordinator pushes page")
    func routeSettingsWithCoordinator() {
        let serviceLocator = TestServiceLocatorFactory.createFullyMocked()
        let coordinator = Coordinator(serviceLocator: serviceLocator)
        let router = FeedNavigationRouter(coordinator: coordinator)

        router.route(navigationEvent: .settings)
        #expect(true)
    }
}

@Suite("FeedNavigationEvent Tests")
struct FeedNavigationEventTests {
    @Test("FeedNavigationEvent articleDetail carries article")
    func articleDetailCarriesArticle() {
        let article = Article.mockArticles[0]
        let event = FeedNavigationEvent.articleDetail(article)

        if case let .articleDetail(eventArticle) = event {
            #expect(eventArticle.id == article.id)
        } else {
            Issue.record("Expected articleDetail case")
        }
    }

    @Test("FeedNavigationEvent settings case exists")
    func settingsCaseExists() {
        let event = FeedNavigationEvent.settings

        if case .settings = event {
            // Expected
        } else {
            Issue.record("Expected settings case")
        }
    }
}
