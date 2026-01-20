import Foundation
@testable import Pulse
import Testing

@Suite("DailyDigest Model Tests")
struct DailyDigestTests {
    // MARK: - Test Data

    private var fixedDate: Date {
        Date(timeIntervalSince1970: 1_672_531_200) // Jan 1, 2023
    }

    private var mockArticles: [Article] {
        [
            Article(
                id: "1",
                title: "Tech News Today",
                source: ArticleSource(id: "tech", name: "TechCrunch"),
                url: "https://example.com/1",
                publishedAt: fixedDate,
                category: .technology
            ),
            Article(
                id: "2",
                title: "Business Update",
                source: ArticleSource(id: "biz", name: "Reuters"),
                url: "https://example.com/2",
                publishedAt: fixedDate,
                category: .business
            ),
            Article(
                id: "3",
                title: "More Tech Stories",
                source: ArticleSource(id: "tech2", name: "Wired"),
                url: "https://example.com/3",
                publishedAt: fixedDate,
                category: .technology
            ),
        ]
    }

    // MARK: - formattedDate Tests

    @Test("formattedDate returns correct locale-specific format")
    func formattedDateReturnsCorrectFormat() {
        // Use a date in the middle of a month to avoid timezone edge cases
        let testDate = Date(timeIntervalSince1970: 1_673_740_800) // Jan 15, 2023 00:00:00 UTC

        let digest = DailyDigest(
            id: "test-digest",
            summary: "Test summary",
            sourceArticles: [],
            generatedAt: testDate
        )

        let formattedDate = digest.formattedDate

        // The date formatter uses .long style, should contain the year
        #expect(!formattedDate.isEmpty)
        // The formatted date should contain either 2023 or January (depending on locale)
        #expect(formattedDate.contains("2023") || formattedDate.contains("January") || formattedDate.contains("15"))
    }

    // MARK: - articleCount Tests

    @Test("articleCount returns count of source articles")
    func articleCountReturnsCorrectCount() {
        let digest = DailyDigest(
            id: "test-digest",
            summary: "Test summary",
            sourceArticles: mockArticles,
            generatedAt: fixedDate
        )

        #expect(digest.articleCount == 3)
    }

    @Test("articleCount returns 0 for empty source articles")
    func articleCountReturnsZeroForEmpty() {
        let digest = DailyDigest(
            id: "test-digest",
            summary: "Test summary",
            sourceArticles: [],
            generatedAt: fixedDate
        )

        #expect(digest.articleCount == 0)
    }

    // MARK: - categoryBreakdown Tests

    @Test("categoryBreakdown groups articles by category correctly")
    func categoryBreakdownGroupsCorrectly() {
        let digest = DailyDigest(
            id: "test-digest",
            summary: "Test summary",
            sourceArticles: mockArticles,
            generatedAt: fixedDate
        )

        let breakdown = digest.categoryBreakdown

        #expect(breakdown[.technology] == 2)
        #expect(breakdown[.business] == 1)
        #expect(breakdown[.health] == nil) // Not present
    }

    @Test("categoryBreakdown handles articles without categories")
    func categoryBreakdownHandlesNilCategories() {
        let articlesWithNilCategories = [
            Article(
                id: "1",
                title: "Article with category",
                source: ArticleSource(id: "test", name: "Test"),
                url: "https://example.com/1",
                publishedAt: fixedDate,
                category: .world
            ),
            Article(
                id: "2",
                title: "Article without category",
                source: ArticleSource(id: "test", name: "Test"),
                url: "https://example.com/2",
                publishedAt: fixedDate,
                category: nil
            ),
        ]

        let digest = DailyDigest(
            id: "test-digest",
            summary: "Test summary",
            sourceArticles: articlesWithNilCategories,
            generatedAt: fixedDate
        )

        let breakdown = digest.categoryBreakdown

        // Only the article with category should be counted
        #expect(breakdown[.world] == 1)
        #expect(breakdown.count == 1)
    }

    @Test("categoryBreakdown returns empty dictionary for no articles")
    func categoryBreakdownReturnsEmptyForNoArticles() {
        let digest = DailyDigest(
            id: "test-digest",
            summary: "Test summary",
            sourceArticles: [],
            generatedAt: fixedDate
        )

        let breakdown = digest.categoryBreakdown

        #expect(breakdown.isEmpty)
    }

    // MARK: - Equatable Tests

    @Test("DailyDigest equality comparison works correctly")
    func equalityComparison() {
        let digest1 = DailyDigest(
            id: "same-id",
            summary: "Summary",
            sourceArticles: [],
            generatedAt: fixedDate
        )

        let digest2 = DailyDigest(
            id: "same-id",
            summary: "Summary",
            sourceArticles: [],
            generatedAt: fixedDate
        )

        let digest3 = DailyDigest(
            id: "different-id",
            summary: "Summary",
            sourceArticles: [],
            generatedAt: fixedDate
        )

        #expect(digest1 == digest2)
        #expect(digest1 != digest3)
    }

    // MARK: - Identifiable Tests

    @Test("DailyDigest id property returns correct value")
    func identifiableProperty() {
        let digest = DailyDigest(
            id: "unique-digest-id",
            summary: "Test summary",
            sourceArticles: [],
            generatedAt: fixedDate
        )

        #expect(digest.id == "unique-digest-id")
    }
}
