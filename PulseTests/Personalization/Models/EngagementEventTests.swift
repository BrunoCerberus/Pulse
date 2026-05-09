import Foundation
@testable import Pulse
import Testing

@Suite("EngagementEvent Tests")
struct EngagementEventTests {
    private static let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)

    private var testArticle: Article {
        Article(
            id: "article-1",
            title: "Test Article",
            description: "Test description",
            content: nil,
            author: nil,
            source: ArticleSource(id: "src", name: "Test Source"),
            url: "https://example.com/1",
            imageURL: nil,
            publishedAt: Self.referenceDate,
            category: .technology
        )
    }

    @Test("Default weight is positive for engagement signals")
    func defaultWeightForEngagementSignals() {
        #expect(EngagementEvent.defaultWeight(for: .read30s) == 1.0)
        #expect(EngagementEvent.defaultWeight(for: .completedRead) == 2.0)
        #expect(EngagementEvent.defaultWeight(for: .bookmarked) == 3.0)
        #expect(EngagementEvent.defaultWeight(for: .shared) == 4.0)
    }

    @Test("Default weight is negative for dismissal")
    func defaultWeightForDismissal() {
        #expect(EngagementEvent.defaultWeight(for: .dismissed) == -1.0)
    }

    @Test("Init from article snapshots title, summary, and category")
    func initFromArticleSnapshotsFields() {
        let event = EngagementEvent(from: testArticle, kind: .bookmarked)

        #expect(event.articleID == testArticle.id)
        #expect(event.articleTitle == testArticle.title)
        #expect(event.articleSummary == testArticle.description)
        #expect(event.categoryRaw == NewsCategory.technology.rawValue)
        #expect(event.kind == .bookmarked)
        #expect(event.weight == 3.0)
    }

    @Test("Init from article uses default weight when none provided")
    func initFromArticleDefaultsWeight() {
        let event = EngagementEvent(from: testArticle, kind: .shared)
        #expect(event.weight == 4.0)
    }

    @Test("Init from article respects explicit weight override")
    func initFromArticleRespectsExplicitWeight() {
        let event = EngagementEvent(from: testArticle, kind: .read30s, weight: 99.0)
        #expect(event.weight == 99.0)
    }

    @Test("Init from article without category leaves categoryRaw nil")
    func initFromArticleWithoutCategory() {
        let articleNoCategory = Article(
            id: "x",
            title: "x",
            source: ArticleSource(id: nil, name: "src"),
            url: "https://x",
            publishedAt: Self.referenceDate,
            category: nil
        )
        let event = EngagementEvent(from: articleNoCategory, kind: .read30s)
        #expect(event.categoryRaw == nil)
    }

    @Test("Each event gets a unique ID by default")
    func eachEventHasUniqueID() {
        let first = EngagementEvent(from: testArticle, kind: .read30s)
        let second = EngagementEvent(from: testArticle, kind: .read30s)
        #expect(first.id != second.id)
    }

    @Test("Codable round-trip preserves all fields")
    func codableRoundTrip() throws {
        let original = EngagementEvent(from: testArticle, kind: .completedRead)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(EngagementEvent.self, from: data)
        #expect(decoded == original)
    }
}
