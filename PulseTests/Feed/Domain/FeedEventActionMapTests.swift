import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("FeedEventActionMap Tests")
struct FeedEventActionMapTests {
    let sut = FeedEventActionMap()

    @Test("onAppear event maps to loadInitialData action")
    func onAppearMapping() {
        let action = sut.map(event: .onAppear)
        #expect(action == .loadInitialData)
    }

    @Test("onGenerateDigestTapped event maps to generateDigest action")
    func onGenerateDigestTappedMapping() {
        let action = sut.map(event: .onGenerateDigestTapped)
        #expect(action == .generateDigest)
    }

    @Test("onArticleTapped event maps to selectArticle action with correct article")
    func onArticleTappedMapping() {
        let testArticle = Article.mockArticles[0]
        let action = sut.map(event: .onArticleTapped(testArticle))

        #expect(action == .selectArticle(testArticle))
    }

    @Test("onArticleNavigated event maps to clearSelectedArticle action")
    func onArticleNavigatedMapping() {
        let action = sut.map(event: .onArticleNavigated)
        #expect(action == .clearSelectedArticle)
    }

    @Test("onRetryTapped event maps to generateDigest action")
    func onRetryTappedMapping() {
        let action = sut.map(event: .onRetryTapped)
        #expect(action == .generateDigest)
    }

    @Test("onDismissError event maps to clearError action")
    func onDismissErrorMapping() {
        let action = sut.map(event: .onDismissError)
        #expect(action == .clearError)
    }

    @Test("All events produce non-nil actions")
    func allEventsProduceActions() {
        let testArticle = Article.mockArticles[0]
        let events: [FeedViewEvent] = [
            .onAppear,
            .onGenerateDigestTapped,
            .onArticleTapped(testArticle),
            .onArticleNavigated,
            .onRetryTapped,
            .onDismissError,
        ]

        for event in events {
            let action = sut.map(event: event)
            #expect(action != nil, "Event \(event) should produce a non-nil action")
        }
    }

    @Test("Article is preserved in selectArticle action")
    func articlePreservedInAction() {
        let articles = Article.mockArticles

        for article in articles {
            let action = sut.map(event: .onArticleTapped(article))

            if case let .selectArticle(mappedArticle) = action {
                #expect(mappedArticle.id == article.id)
                #expect(mappedArticle.title == article.title)
            } else {
                Issue.record("Expected selectArticle action for article \(article.id)")
            }
        }
    }
}
