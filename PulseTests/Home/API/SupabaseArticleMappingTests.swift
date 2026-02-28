import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("SupabaseArticle Mapping Tests")
struct SupabaseArticleMappingTests {
    @Test("Article with both content and summary maps correctly")
    func contentAndSummaryMappedCorrectly() {
        let article = createSupabaseArticle(
            summary: "Short summary for preview",
            content: "Full article content with lots of details..."
        )

        let mapped = article.toArticle()

        #expect(mapped.description == "Short summary for preview")
        #expect(mapped.content == "Full article content with lots of details...")
    }

    @Test("Article with only summary uses it as content without description")
    func onlySummaryUsedAsContent() {
        let article = createSupabaseArticle(
            summary: "This is the only text from RSS feed",
            content: nil
        )

        let mapped = article.toArticle()

        #expect(mapped.description == nil)
        #expect(mapped.content == "This is the only text from RSS feed")
    }

    @Test("Article with empty content uses summary as content")
    func emptyContentUsesSummary() {
        let article = createSupabaseArticle(
            summary: "Summary text here",
            content: ""
        )

        let mapped = article.toArticle()

        #expect(mapped.description == nil)
        #expect(mapped.content == "Summary text here")
    }

    @Test("Article with no content or summary has nil values")
    func noContentOrSummary() {
        let article = createSupabaseArticle(
            summary: nil,
            content: nil
        )

        let mapped = article.toArticle()

        #expect(mapped.description == nil)
        #expect(mapped.content == nil)
    }

    @Test("Image URL maps correctly")
    func imageURLMapsCorrectly() {
        let article = createSupabaseArticle(
            imageUrl: "https://example.com/full.jpg"
        )

        let mapped = article.toArticle()

        #expect(mapped.imageURL == "https://example.com/full.jpg")
        #expect(mapped.thumbnailURL == "https://example.com/full.jpg")
    }

    @Test("Nil image URL results in nil values")
    func nilImageURLResultsInNilValues() {
        let article = createSupabaseArticle(
            imageUrl: nil
        )

        let mapped = article.toArticle()

        #expect(mapped.imageURL == nil)
        #expect(mapped.thumbnailURL == nil)
    }

    @Test("Parses ISO8601 date with fractional seconds")
    func parsesDateWithFractionalSeconds() throws {
        let article = createSupabaseArticle(
            publishedAt: "2024-01-15T10:30:00.000Z"
        )

        let mapped = article.toArticle()

        let calendar = Calendar(identifier: .gregorian)
        let timeZone = try #require(TimeZone(identifier: "UTC"))
        let components = calendar.dateComponents(in: timeZone, from: mapped.publishedAt)

        #expect(components.year == 2024)
        #expect(components.month == 1)
        #expect(components.day == 15)
        #expect(components.hour == 10)
        #expect(components.minute == 30)
    }

    @Test("Parses ISO8601 date without fractional seconds")
    func parsesDateWithoutFractionalSeconds() throws {
        let article = createSupabaseArticle(
            publishedAt: "2024-06-20T14:45:00Z"
        )

        let mapped = article.toArticle()

        let calendar = Calendar(identifier: .gregorian)
        let timeZone = try #require(TimeZone(identifier: "UTC"))
        let components = calendar.dateComponents(in: timeZone, from: mapped.publishedAt)

        #expect(components.year == 2024)
        #expect(components.month == 6)
        #expect(components.day == 20)
    }

    @Test("Source maps correctly from flat fields")
    func sourceMapsCorrectly() {
        let article = createSupabaseArticle(
            sourceName: "TechCrunch",
            sourceSlug: "techcrunch"
        )

        let mapped = article.toArticle()

        #expect(mapped.source.id == "techcrunch")
        #expect(mapped.source.name == "TechCrunch")
    }

    @Test("Missing source uses Unknown as name")
    func missingSourceUsesUnknown() {
        let article = createSupabaseArticle(
            sourceName: nil,
            sourceSlug: nil
        )

        let mapped = article.toArticle()

        #expect(mapped.source.name == "Unknown")
    }

    @Test("Category maps to NewsCategory when slug matches")
    func categoryMapsWhenSlugMatches() {
        let article = createSupabaseArticle(
            categorySlug: "technology"
        )

        let mapped = article.toArticle()

        #expect(mapped.category == .technology)
    }

    @Test("Category is nil when slug does not match NewsCategory")
    func categoryNilWhenNoMatch() {
        let article = createSupabaseArticle(
            categorySlug: "random-category"
        )

        let mapped = article.toArticle()

        #expect(mapped.category == nil)
    }

    @Test("Category is nil when slug is nil")
    func categoryNilWhenSlugNil() {
        let article = createSupabaseArticle(
            categorySlug: nil
        )

        let mapped = article.toArticle()

        #expect(mapped.category == nil)
    }

    private func createSupabaseArticle(
        id: String = "test-id",
        title: String = "Test Title",
        summary: String? = "Test summary",
        content: String? = "Test content",
        url: String = "https://example.com/article",
        imageUrl: String? = "https://example.com/image.jpg",
        publishedAt: String = "2024-01-15T10:30:00.000Z",
        sourceName: String? = "Test Source",
        sourceSlug: String? = "test-source",
        categoryName: String? = "Technology",
        categorySlug: String? = "technology",
        mediaType: String? = nil,
        mediaUrl: String? = nil,
        mediaDuration: Int? = nil,
        mediaMimeType: String? = nil
    ) -> SupabaseArticle {
        SupabaseArticle(
            id: id,
            title: title,
            summary: summary,
            content: content,
            url: url,
            imageUrl: imageUrl,
            publishedAt: publishedAt,
            sourceName: sourceName,
            sourceSlug: sourceSlug,
            categoryName: categoryName,
            categorySlug: categorySlug,
            mediaType: mediaType,
            mediaUrl: mediaUrl,
            mediaDuration: mediaDuration,
            mediaMimeType: mediaMimeType
        )
    }
}
