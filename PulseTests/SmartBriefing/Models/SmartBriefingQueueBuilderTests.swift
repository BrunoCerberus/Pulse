import Foundation
@testable import Pulse
import Testing

@Suite("SmartBriefingQueueBuilder Tests")
struct SmartBriefingQueueBuilderTests {
    @Test("unreadSinceLastBriefing filters out articles published before the cutoff")
    func filtersByPublishedDate() {
        let cutoff = Date(timeIntervalSince1970: 1_700_000_000)
        let pool = Article.mockArticles
        let result = SmartBriefingQueueBuilder.filterPool(
            pool,
            scope: .unreadSinceLastBriefing,
            lastServedAt: cutoff,
            servedArticleIDs: []
        )

        #expect(result.allSatisfy { $0.publishedAt > cutoff })
        #expect(result.count < pool.count)
    }

    @Test("servedArticleIDs are excluded regardless of scope")
    func excludesServedIDs() {
        let pool = Article.mockArticles
        let served: Set = ["1", "2"]

        let unreadResult = SmartBriefingQueueBuilder.filterPool(
            pool,
            scope: .unreadSinceLastBriefing,
            lastServedAt: nil,
            servedArticleIDs: served
        )
        let allUnreadResult = SmartBriefingQueueBuilder.filterPool(
            pool,
            scope: .allUnread,
            lastServedAt: nil,
            servedArticleIDs: served
        )

        #expect(!unreadResult.contains { served.contains($0.id) })
        #expect(!allUnreadResult.contains { served.contains($0.id) })
    }

    @Test("allUnread ignores the published-date cutoff")
    func allUnreadIgnoresCutoff() {
        let farFutureCutoff = Date.distantFuture
        let pool = Article.mockArticles

        let result = SmartBriefingQueueBuilder.filterPool(
            pool,
            scope: .allUnread,
            lastServedAt: farFutureCutoff,
            servedArticleIDs: []
        )

        #expect(result.count == pool.count)
    }

    @Test("First run (nil lastServedAt) returns the full pool, minus served IDs")
    func firstRunReturnsFullPool() {
        let pool = Article.mockArticles

        let result = SmartBriefingQueueBuilder.filterPool(
            pool,
            scope: .unreadSinceLastBriefing,
            lastServedAt: nil,
            servedArticleIDs: []
        )

        #expect(result.count == pool.count)
    }
}
