import Foundation
@testable import Pulse
import Testing

@Suite("SupabaseArticle Basic Tests")
struct SupabaseArticleBasicTests {
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
}
