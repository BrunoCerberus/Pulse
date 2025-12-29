import Foundation
@testable import Pulse
import Testing

@Suite("HomeEventActionMap Tests")
struct HomeEventActionMapTests {
    let sut = HomeEventActionMap()

    // MARK: - Event Mapping Tests (Consolidated)

    @Test("All events map to correct actions")
    func allEventsMappingToCorrectActions() {
        let article = Article.mockArticles[0]

        // Test all event → action mappings
        #expect(sut.map(event: .onAppear) == .loadInitialData)
        #expect(sut.map(event: .onRefresh) == .refresh)
        #expect(sut.map(event: .onLoadMore) == .loadMoreHeadlines)
        #expect(sut.map(event: .onArticleTapped(article)) == .selectArticle(article))
        #expect(sut.map(event: .onBookmarkTapped(article)) == .bookmarkArticle(article))
        #expect(sut.map(event: .onShareTapped(article)) == .shareArticle(article))
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
