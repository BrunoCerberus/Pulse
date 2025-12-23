import Foundation
@testable import Pulse
import Testing

@Suite("HomeEventActionMap Tests")
struct HomeEventActionMapTests {
    let sut = HomeEventActionMap()

    // MARK: - Event Mapping Tests

    @Test("onAppear maps to loadInitialData")
    func onAppearMapsToLoadInitialData() {
        let action = sut.map(event: .onAppear)

        #expect(action == .loadInitialData)
    }

    @Test("onRefresh maps to refresh")
    func onRefreshMapsToRefresh() {
        let action = sut.map(event: .onRefresh)

        #expect(action == .refresh)
    }

    @Test("onLoadMore maps to loadMoreHeadlines")
    func onLoadMoreMapsToLoadMoreHeadlines() {
        let action = sut.map(event: .onLoadMore)

        #expect(action == .loadMoreHeadlines)
    }

    @Test("onArticleTapped maps to selectArticle with article")
    func onArticleTappedMapsToSelectArticle() {
        let article = Article.mockArticles[0]

        let action = sut.map(event: .onArticleTapped(article))

        #expect(action == .selectArticle(article))
    }

    @Test("onBookmarkTapped maps to bookmarkArticle with article")
    func onBookmarkTappedMapsToBookmarkArticle() {
        let article = Article.mockArticles[0]

        let action = sut.map(event: .onBookmarkTapped(article))

        #expect(action == .bookmarkArticle(article))
    }

    @Test("onShareTapped maps to shareArticle with article")
    func onShareTappedMapsToShareArticle() {
        let article = Article.mockArticles[0]

        let action = sut.map(event: .onShareTapped(article))

        #expect(action == .shareArticle(article))
    }

    // MARK: - All Events Have Mappings

    @Test("All events produce non-nil actions")
    func allEventsProduceActions() {
        let article = Article.mockArticles[0]
        let events: [HomeViewEvent] = [
            .onAppear,
            .onRefresh,
            .onLoadMore,
            .onArticleTapped(article),
            .onBookmarkTapped(article),
            .onShareTapped(article),
        ]

        for event in events {
            let action = sut.map(event: event)
            #expect(action != nil)
        }
    }
}
