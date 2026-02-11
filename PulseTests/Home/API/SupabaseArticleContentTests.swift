import Foundation
@testable import Pulse
import Testing

@Suite("SupabaseArticle Content Tests")
struct SupabaseArticleContentTests {
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
}
