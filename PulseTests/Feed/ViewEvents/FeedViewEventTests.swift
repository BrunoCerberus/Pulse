import Foundation
@testable import Pulse
import Testing

@Suite("FeedViewEvent Tests")
struct FeedViewEventTests {
    @Test("onAppear event") func onAppear() {
        #expect(FeedViewEvent.onAppear == .onAppear)
    }

    @Test("onGenerateDigestTapped event") func onGenerateDigestTapped() {
        #expect(FeedViewEvent.onGenerateDigestTapped == .onGenerateDigestTapped)
    }

    @Test("onArticleTapped event") func onArticleTapped() {
        let article = Article.mockArticles[0]
        let event = FeedViewEvent.onArticleTapped(article)
        if case let .onArticleTapped(tappedArticle) = event { #expect(tappedArticle.id == article.id) }
    }

    @Test("onArticleNavigated event") func onArticleNavigated() {
        #expect(FeedViewEvent.onArticleNavigated == .onArticleNavigated)
    }

    @Test("onRetryTapped event") func onRetryTapped() {
        #expect(FeedViewEvent.onRetryTapped == .onRetryTapped)
    }

    @Test("onDismissError event") func onDismissError() {
        #expect(FeedViewEvent.onDismissError == .onDismissError)
    }
}
