import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("FeedNavigationRouter Tests")
@MainActor
struct FeedNavigationRouterTests {
    @Test("Router initializes without crashing")
    func routerInitializes() {
        let router = FeedNavigationRouter()
        #expect(router != nil)
    }

    @Test("Navigate to article event is handled")
    func navigateToArticle() {
        let router = FeedNavigationRouter()
        let article = Article.mockArticles[0]

        // Should not throw
        router.route(navigationEvent: .articleDetail(article))
    }
}
