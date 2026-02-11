import Foundation
@testable import Pulse
import Testing

// MARK: - SupabaseArticle Tests

@Suite("SupabaseArticle Tests")
struct SupabaseArticleTests {
    @Test("toArticle maps all fields correctly")
    func toArticleMapsFields() {
        let supabaseArticle = SupabaseArticle(
            id: "test-id",
            title: "Test Title",
            summary: "Test summary",
            content: "Full content here",
            url: "https://example.com/article",
            imageUrl: "https://example.com/image.jpg",
            publishedAt: "2026-01-15T10:30:00+00:00",
            sourceName: "Test Source",
            sourceSlug: "test-source",
            categoryName: "Technology",
            categorySlug: "technology",
            mediaType: nil,
            mediaUrl: nil,
            mediaDuration: nil,
            mediaMimeType: nil
        )

        let article = supabaseArticle.toArticle()

        #expect(article.id == "test-id")
        #expect(article.title == "Test Title")
        #expect(article.description == "Test summary")
        #expect(article.content == "Full content here")
        #expect(article.url == "https://example.com/article")
        #expect(article.imageURL == "https://example.com/image.jpg")
        #expect(article.source.name == "Test Source")
        #expect(article.source.id == "test-source")
        #expect(article.category == .technology)
    }

    @Test("toArticle handles nil optional fields")
    func toArticleHandlesNils() {
        let supabaseArticle = SupabaseArticle(
            id: "test-id",
            title: "Test Title",
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

        let article = supabaseArticle.toArticle()

        #expect(article.source.name == "Unknown")
        #expect(article.category == nil)
        #expect(article.imageURL == nil)
        #expect(article.description == nil)
        #expect(article.content == nil)
    }

    @Test("toArticle parses ISO8601 date with fractional seconds")
    func parsesDateWithFractionalSeconds() throws {
        let supabaseArticle = SupabaseArticle(
            id: "test-id",
            title: "Test",
            summary: nil,
            content: nil,
            url: "https://example.com",
            imageUrl: nil,
            publishedAt: "2026-01-15T10:30:00.123+00:00",
            sourceName: nil,
            sourceSlug: nil,
            categoryName: nil,
            categorySlug: nil,
            mediaType: nil,
            mediaUrl: nil,
            mediaDuration: nil,
            mediaMimeType: nil
        )

        let article = supabaseArticle.toArticle()
        let calendar = Calendar(identifier: .gregorian)
        let utc = try #require(TimeZone(identifier: "UTC"))
        let components = calendar.dateComponents(in: utc, from: article.publishedAt)

        #expect(components.year == 2026)
        #expect(components.month == 1)
        #expect(components.day == 15)
    }

    @Test("toArticle parses ISO8601 date without fractional seconds")
    func parsesDateWithoutFractionalSeconds() throws {
        let supabaseArticle = SupabaseArticle(
            id: "test-id",
            title: "Test",
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

        let article = supabaseArticle.toArticle()
        let calendar = Calendar(identifier: .gregorian)
        let utc = try #require(TimeZone(identifier: "UTC"))
        let components = calendar.dateComponents(in: utc, from: article.publishedAt)

        #expect(components.year == 2026)
        #expect(components.month == 1)
    }

    @Test("toArticle uses content for description and content when both exist")
    func descriptionAndContentMapping() {
        let supabaseArticle = SupabaseArticle(
            id: "test-id",
            title: "Test",
            summary: "Short summary",
            content: "Full article content",
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

        let article = supabaseArticle.toArticle()

        #expect(article.description == "Short summary")
        #expect(article.content == "Full article content")
    }

    @Test("toArticle uses summary as content when no content exists")
    func summaryAsContentWhenNoContent() {
        let supabaseArticle = SupabaseArticle(
            id: "test-id",
            title: "Test",
            summary: "Only summary",
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

        let article = supabaseArticle.toArticle()

        #expect(article.description == nil)
        #expect(article.content == "Only summary")
    }

    @Test("toArticle derives podcast media type from mediaType field")
    func derivesPodcastMediaType() {
        let supabaseArticle = SupabaseArticle(
            id: "test-id",
            title: "Test Podcast",
            summary: nil,
            content: nil,
            url: "https://example.com",
            imageUrl: nil,
            publishedAt: "2026-01-15T10:30:00+00:00",
            sourceName: nil,
            sourceSlug: nil,
            categoryName: nil,
            categorySlug: nil,
            mediaType: "podcast",
            mediaUrl: "https://example.com/audio.mp3",
            mediaDuration: 3600,
            mediaMimeType: "audio/mpeg"
        )

        let article = supabaseArticle.toArticle()

        #expect(article.mediaType == .podcast)
        #expect(article.mediaURL == "https://example.com/audio.mp3")
        #expect(article.mediaDuration == 3600)
    }

    @Test("toArticle derives video media type from mediaType field")
    func derivesVideoMediaType() {
        let supabaseArticle = SupabaseArticle(
            id: "test-id",
            title: "Test Video",
            summary: nil,
            content: nil,
            url: "https://example.com",
            imageUrl: nil,
            publishedAt: "2026-01-15T10:30:00+00:00",
            sourceName: nil,
            sourceSlug: nil,
            categoryName: nil,
            categorySlug: nil,
            mediaType: "video",
            mediaUrl: "https://example.com/video.mp4",
            mediaDuration: 600,
            mediaMimeType: "video/mp4"
        )

        let article = supabaseArticle.toArticle()

        #expect(article.mediaType == .video)
    }

    @Test("toArticle derives media type from category slug fallback")
    func derivesMediaTypeFromCategorySlug() {
        let podcastArticle = SupabaseArticle(
            id: "test-id",
            title: "Test",
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

        let article = podcastArticle.toArticle()
        #expect(article.mediaType == .podcast)

        let videoArticle = SupabaseArticle(
            id: "test-id-2",
            title: "Test",
            summary: nil,
            content: nil,
            url: "https://example.com",
            imageUrl: nil,
            publishedAt: "2026-01-15T10:30:00+00:00",
            sourceName: nil,
            sourceSlug: nil,
            categoryName: nil,
            categorySlug: "videos",
            mediaType: nil,
            mediaUrl: nil,
            mediaDuration: nil,
            mediaMimeType: nil
        )

        let videoResult = videoArticle.toArticle()
        #expect(videoResult.mediaType == .video)
    }

    @Test("toArticle returns nil media type for unknown type")
    func unknownMediaTypeReturnsNil() {
        let supabaseArticle = SupabaseArticle(
            id: "test-id",
            title: "Test",
            summary: nil,
            content: nil,
            url: "https://example.com",
            imageUrl: nil,
            publishedAt: "2026-01-15T10:30:00+00:00",
            sourceName: nil,
            sourceSlug: nil,
            categoryName: nil,
            categorySlug: nil,
            mediaType: "unknown",
            mediaUrl: nil,
            mediaDuration: nil,
            mediaMimeType: nil
        )

        let article = supabaseArticle.toArticle()
        #expect(article.mediaType == nil)
    }

    @Test("toArticle uses article URL as mediaURL fallback when no mediaUrl")
    func mediaURLFallbackToArticleURL() {
        let supabaseArticle = SupabaseArticle(
            id: "test-id",
            title: "Test",
            summary: nil,
            content: nil,
            url: "https://example.com/article",
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

        let article = supabaseArticle.toArticle()
        #expect(article.mediaURL == "https://example.com/article")
    }
}

// MARK: - SupabaseSearchResult Tests

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
