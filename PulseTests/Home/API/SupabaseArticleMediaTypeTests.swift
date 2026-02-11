import Foundation
@testable import Pulse
import Testing

@Suite("SupabaseArticle Media Type Tests")
struct SupabaseArticleMediaTypeTests {
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
