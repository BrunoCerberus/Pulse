import Foundation
@testable import Pulse
import Testing

@Suite("HomeEventActionMap Tests")
struct HomeEventActionMapTests {
    let sut = HomeEventActionMap()

    // MARK: - Event Mapping Tests (Consolidated)

    @Test("All events map to correct actions")
    func allEventsMappingToCorrectActions() {
        let articleId = Article.mockArticles[0].id

        // Test all event → action mappings
        #expect(sut.map(event: .onAppear) == .loadInitialData)
        #expect(sut.map(event: .onRefresh) == .refresh)
        #expect(sut.map(event: .onLoadMore) == .loadMoreHeadlines)
        #expect(sut.map(event: .onArticleTapped(articleId: articleId)) == .selectArticle(articleId: articleId))
        #expect(sut.map(event: .onBookmarkTapped(articleId: articleId)) == .bookmarkArticle(articleId: articleId))
        #expect(sut.map(event: .onShareTapped(articleId: articleId)) == .shareArticle(articleId: articleId))
    }

    // MARK: - All Events Have Mappings

    @Test("All events produce non-nil actions")
    func allEventsProduceActions() {
        let articleId = Article.mockArticles[0].id
        let events: [HomeViewEvent] = [
            .onAppear,
            .onRefresh,
            .onLoadMore,
            .onArticleTapped(articleId: articleId),
            .onBookmarkTapped(articleId: articleId),
            .onShareTapped(articleId: articleId),
        ]

        for event in events {
            let action = sut.map(event: event)
            #expect(action != nil)
        }
    }
}
