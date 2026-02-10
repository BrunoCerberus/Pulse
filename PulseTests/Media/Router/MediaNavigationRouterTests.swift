import Foundation
@testable import Pulse
import Testing

@Suite("MediaNavigationRouter Tests")
@MainActor
struct MediaNavigationRouterTests {
    @Test("Router initializes with nil coordinator")
    func initWithNilCoordinator() {
        let router = MediaNavigationRouter(coordinator: nil)
        #expect(router.navigation == nil)
    }

    @Test("Router initializes with coordinator")
    func initWithCoordinator() {
        let serviceLocator = TestServiceLocatorFactory.createFullyMocked()
        let coordinator = Coordinator(serviceLocator: serviceLocator)
        let router = MediaNavigationRouter(coordinator: coordinator)

        // Router should be created successfully
        #expect(router.navigation == nil) // No UIKit navigation in SwiftUI mode
    }

    @Test("Two routers with same coordinator are equal")
    func equalityWithSameCoordinator() {
        let serviceLocator = TestServiceLocatorFactory.createFullyMocked()
        let coordinator = Coordinator(serviceLocator: serviceLocator)
        let router1 = MediaNavigationRouter(coordinator: coordinator)
        let router2 = MediaNavigationRouter(coordinator: coordinator)

        #expect(router1 == router2)
    }

    @Test("Two routers with different coordinators are not equal")
    func inequalityWithDifferentCoordinators() {
        let serviceLocator1 = TestServiceLocatorFactory.createFullyMocked()
        let serviceLocator2 = TestServiceLocatorFactory.createFullyMocked()
        let coordinator1 = Coordinator(serviceLocator: serviceLocator1)
        let coordinator2 = Coordinator(serviceLocator: serviceLocator2)
        let router1 = MediaNavigationRouter(coordinator: coordinator1)
        let router2 = MediaNavigationRouter(coordinator: coordinator2)

        #expect(router1 != router2)
    }

    @Test("Two routers with nil coordinators are equal")
    func equalityWithNilCoordinators() {
        let router1 = MediaNavigationRouter(coordinator: nil)
        let router2 = MediaNavigationRouter(coordinator: nil)

        #expect(router1 == router2)
    }
}

@Suite("MediaNavigationEvent Tests")
struct MediaNavigationEventTests {
    @Test("MediaNavigationEvent mediaDetail carries article")
    func mediaDetailCarriesArticle() {
        let article = Article.mockArticles[0]
        let event = MediaNavigationEvent.mediaDetail(article)

        if case let .mediaDetail(eventArticle) = event {
            #expect(eventArticle.id == article.id)
        } else {
            Issue.record("Expected mediaDetail case")
        }
    }
}
