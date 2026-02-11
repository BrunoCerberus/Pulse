import Foundation
@testable import Pulse
import Testing

@Suite("SupabaseSearchResult Tests")
struct SupabaseSearchResultTests {
    @Test("toArticle maps search result fields correctly")
    func toArticleMapsFields() {
        let searchResult = SupabaseSearchResult(
            id: "search-id",
            title: "Search Result",
            summary: "Search summary",
            content: "Search content",
            url: "https://example.com/search",
            imageUrl: "https://example.com/img.jpg",
            publishedAt: "2026-01-15T10:30:00+00:00",
            sourceName: "Source",
            sourceSlug: "source-slug",
            categoryName: "Business",
            categorySlug: "business",
            mediaType: nil,
            mediaUrl: nil,
            mediaDuration: nil,
            mediaMimeType: nil
        )

        let article = searchResult.toArticle()

        #expect(article.id == "search-id")
        #expect(article.title == "Search Result")
        #expect(article.description == "Search summary")
        #expect(article.content == "Search content")
        #expect(article.category == .business)
        #expect(article.source.name == "Source")
    }

    @Test("toArticle handles nil fields in search result")
    func toArticleHandlesNils() {
        let searchResult = SupabaseSearchResult(
            id: "search-id",
            title: "Search Result",
            summary: nil,
            content: nil,
            url: "https://example.com",
            imageUrl: nil,
            publishedAt: "2026-01-15T10:30:00+00:00",
            sourceName: nil,
            sourceSlug: nil,
            categoryName: nil,
            categorySlug: nil,
            mediaType: nil,
            mediaUrl: nil,
            mediaDuration: nil,
            mediaMimeType: nil
        )

        let article = searchResult.toArticle()

        #expect(article.source.name == "Unknown")
        #expect(article.category == nil)
        #expect(article.description == nil)
        #expect(article.content == nil)
    }

    @Test("toArticle derives media type from search result")
    func derivesMediaType() {
        let searchResult = SupabaseSearchResult(
            id: "search-id",
            title: "Podcast Result",
            summary: nil,
            content: nil,
            url: "https://example.com",
            imageUrl: nil,
            publishedAt: "2026-01-15T10:30:00+00:00",
            sourceName: nil,
            sourceSlug: nil,
            categoryName: nil,
            categorySlug: "podcasts",
            mediaType: nil,
            mediaUrl: nil,
            mediaDuration: nil,
            mediaMimeType: nil
        )

        let article = searchResult.toArticle()
        #expect(article.mediaType == .podcast)
    }

    @Test("toArticle parses date correctly in search result")
    func parsesDate() throws {
        let searchResult = SupabaseSearchResult(
            id: "search-id",
            title: "Test",
            summary: nil,
            content: nil,
            url: "https://example.com",
            imageUrl: nil,
            publishedAt: "2026-06-20T14:00:00.000+00:00",
            sourceName: nil,
            sourceSlug: nil,
            categoryName: nil,
            categorySlug: nil,
            mediaType: nil,
            mediaUrl: nil,
            mediaDuration: nil,
            mediaMimeType: nil
        )

        let article = searchResult.toArticle()
        let calendar = Calendar(identifier: .gregorian)
        let utc = try #require(TimeZone(identifier: "UTC"))
        let components = calendar.dateComponents(in: utc, from: article.publishedAt)

        #expect(components.year == 2026)
        #expect(components.month == 6)
        #expect(components.day == 20)
    }
}
