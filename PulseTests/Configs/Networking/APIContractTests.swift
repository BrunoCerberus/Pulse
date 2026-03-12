import Foundation
@testable import Pulse
import Testing

// MARK: - Supabase API Contract Tests

@Suite("Supabase API Contract Tests")
struct SupabaseAPIContractTests {
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    // MARK: - Full Article Decoding

    @Test("Decodes full Supabase article list with all fields")
    func decodesFullArticleList() throws {
        let json = """
        [
            {
                "id": "abc-123",
                "title": "Breaking: Swift 6.0 Released",
                "summary": "Apple releases Swift 6.0 with major improvements",
                "content": "<p>Full article content about Swift 6.0...</p>",
                "url": "https://example.com/swift-6",
                "image_url": "https://example.com/swift-6.jpg",
                "published_at": "2026-01-22T05:01:00+00:00",
                "source_name": "The Verge",
                "source_slug": "the-verge",
                "category_name": "Technology",
                "category_slug": "technology",
                "media_type": null,
                "media_url": null,
                "media_duration": null,
                "media_mime_type": null
            }
        ]
        """

        let data = try #require(json.data(using: .utf8))
        let articles = try decoder.decode([SupabaseArticle].self, from: data)

        #expect(articles.count == 1)
        let article = articles[0]
        #expect(article.id == "abc-123")
        #expect(article.title == "Breaking: Swift 6.0 Released")
        #expect(article.summary == "Apple releases Swift 6.0 with major improvements")
        #expect(article.content == "<p>Full article content about Swift 6.0...</p>")
        #expect(article.url == "https://example.com/swift-6")
        #expect(article.imageUrl == "https://example.com/swift-6.jpg")
        #expect(article.publishedAt == "2026-01-22T05:01:00+00:00")
        #expect(article.sourceName == "The Verge")
        #expect(article.sourceSlug == "the-verge")
        #expect(article.categoryName == "Technology")
        #expect(article.categorySlug == "technology")
    }

    // MARK: - Minimal Fields

    @Test("Decodes article with only required fields (optionals nil)")
    func decodesMinimalArticle() throws {
        let json = """
        [
            {
                "id": "min-001",
                "title": "Minimal Article",
                "url": "https://example.com/minimal",
                "published_at": "2026-01-22T12:00:00+00:00"
            }
        ]
        """

        let data = try #require(json.data(using: .utf8))
        let articles = try decoder.decode([SupabaseArticle].self, from: data)

        #expect(articles.count == 1)
        let article = articles[0]
        #expect(article.id == "min-001")
        #expect(article.title == "Minimal Article")
        #expect(article.summary == nil)
        #expect(article.content == nil)
        #expect(article.imageUrl == nil)
        #expect(article.sourceName == nil)
        #expect(article.sourceSlug == nil)
        #expect(article.categorySlug == nil)
        #expect(article.mediaType == nil)
        #expect(article.mediaUrl == nil)
        #expect(article.mediaDuration == nil)
    }

    // MARK: - Media Type Mapping

    @Test("Podcast media type maps correctly via toArticle()")
    func podcastMediaTypeMapsCorrectly() throws {
        let json = """
        [{
            "id": "pod-001",
            "title": "Tech Podcast Episode",
            "url": "https://example.com/podcast",
            "published_at": "2026-02-01T10:00:00+00:00",
            "media_type": "podcast",
            "media_url": "https://example.com/episode.mp3",
            "media_duration": 3600,
            "media_mime_type": "audio/mpeg"
        }]
        """

        let data = try #require(json.data(using: .utf8))
        let supabaseArticles = try decoder.decode([SupabaseArticle].self, from: data)
        let article = supabaseArticles[0].toArticle()

        #expect(article.mediaType == .podcast)
        #expect(article.mediaURL == "https://example.com/episode.mp3")
        #expect(article.mediaDuration == 3600)
        #expect(article.mediaMimeType == "audio/mpeg")
    }

    @Test("Video media type maps correctly via toArticle()")
    func videoMediaTypeMapsCorrectly() throws {
        let json = """
        [{
            "id": "vid-001",
            "title": "Tech Video",
            "url": "https://example.com/video",
            "published_at": "2026-02-01T10:00:00+00:00",
            "media_type": "video",
            "media_url": "https://example.com/video.mp4",
            "media_duration": 600,
            "media_mime_type": "video/mp4"
        }]
        """

        let data = try #require(json.data(using: .utf8))
        let supabaseArticles = try decoder.decode([SupabaseArticle].self, from: data)
        let article = supabaseArticles[0].toArticle()

        #expect(article.mediaType == .video)
        #expect(article.mediaDuration == 600)
    }

    @Test("Unknown media type results in nil mediaType")
    func unknownMediaTypeReturnsNil() throws {
        let json = """
        [{
            "id": "unk-001",
            "title": "Livestream",
            "url": "https://example.com/live",
            "published_at": "2026-02-01T10:00:00+00:00",
            "media_type": "livestream"
        }]
        """

        let data = try #require(json.data(using: .utf8))
        let supabaseArticles = try decoder.decode([SupabaseArticle].self, from: data)
        let article = supabaseArticles[0].toArticle()

        #expect(article.mediaType == nil)
    }

    // MARK: - Date Parsing

    @Test("Parses date with timezone offset correctly")
    func parsesDateWithTimezoneOffset() throws {
        let json = """
        [{
            "id": "tz-001",
            "title": "Timezone Article",
            "url": "https://example.com/tz",
            "published_at": "2026-01-22T05:01:00+05:30"
        }]
        """

        let data = try #require(json.data(using: .utf8))
        let articles = try decoder.decode([SupabaseArticle].self, from: data)
        let article = articles[0].toArticle()

        // 2026-01-22T05:01:00+05:30 is 2026-01-21T23:31:00Z
        let expectedDate = try #require(ISO8601DateFormatter().date(from: "2026-01-21T23:31:00Z"))
        let interval = article.publishedAt.timeIntervalSince(expectedDate)
        #expect(Swift.abs(interval) < 1)
    }

    @Test("Parses date with fractional seconds")
    func parsesDateWithFractionalSeconds() throws {
        let json = """
        [{
            "id": "frac-001",
            "title": "Fractional Seconds",
            "url": "https://example.com/frac",
            "published_at": "2026-01-22T05:01:00.123+00:00"
        }]
        """

        let data = try #require(json.data(using: .utf8))
        let articles = try decoder.decode([SupabaseArticle].self, from: data)
        let article = articles[0].toArticle()

        // 2026-01-22T05:01:00.123+00:00 is 2026-01-22T05:01:00Z
        let expectedDate = try #require(ISO8601DateFormatter().date(from: "2026-01-22T05:01:00Z"))
        let interval = article.publishedAt.timeIntervalSince(expectedDate)
        #expect(Swift.abs(interval) < 1)
    }

    // MARK: - Extra Unknown Fields Tolerance

    @Test("Decoding tolerates extra unknown fields in JSON")
    func toleratesExtraFields() throws {
        let json = """
        [{
            "id": "extra-001",
            "title": "Extra Fields Article",
            "url": "https://example.com/extra",
            "published_at": "2026-01-22T05:01:00+00:00",
            "unknown_field": "should be ignored",
            "another_unknown": 42
        }]
        """

        let data = try #require(json.data(using: .utf8))
        let articles = try decoder.decode([SupabaseArticle].self, from: data)

        #expect(articles.count == 1)
        #expect(articles[0].id == "extra-001")
    }
}

// MARK: - Supabase Article Mapping Contract Tests

@Suite("Supabase Article Mapping Contract Tests")
struct SupabaseArticleMappingContractTests {
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    @Test("toArticle maps content and summary correctly when both present")
    func toArticleMapsContentAndSummary() throws {
        let json = """
        [{
            "id": "cs-001",
            "title": "Content and Summary",
            "summary": "Short summary",
            "content": "Full content body",
            "url": "https://example.com/cs",
            "published_at": "2026-01-22T05:01:00+00:00"
        }]
        """

        let data = try #require(json.data(using: .utf8))
        let articles = try decoder.decode([SupabaseArticle].self, from: data)
        let article = articles[0].toArticle()

        #expect(article.description == "Short summary")
        #expect(article.content == "Full content body")
    }

    @Test("toArticle uses summary as content when content is nil")
    func toArticleUsesSummaryAsContentWhenNoContent() throws {
        let json = """
        [{
            "id": "so-001",
            "title": "Summary Only",
            "summary": "Only summary text",
            "url": "https://example.com/so",
            "published_at": "2026-01-22T05:01:00+00:00"
        }]
        """

        let data = try #require(json.data(using: .utf8))
        let articles = try decoder.decode([SupabaseArticle].self, from: data)
        let article = articles[0].toArticle()

        #expect(article.description == nil)
        #expect(article.content == "Only summary text")
    }

    @Test("toArticle maps source fields correctly")
    func toArticleMapsSourceFields() throws {
        let json = """
        [{
            "id": "src-001",
            "title": "Source Test",
            "url": "https://example.com/src",
            "published_at": "2026-01-22T05:01:00+00:00",
            "source_name": "TechCrunch",
            "source_slug": "techcrunch",
            "category_slug": "technology"
        }]
        """

        let data = try #require(json.data(using: .utf8))
        let articles = try decoder.decode([SupabaseArticle].self, from: data)
        let article = articles[0].toArticle()

        #expect(article.source.name == "TechCrunch")
        #expect(article.source.id == "techcrunch")
        #expect(article.category == .technology)
    }

    @Test("toArticle defaults source name to Unknown when missing")
    func toArticleDefaultsSourceName() throws {
        let json = """
        [{
            "id": "nosrc-001",
            "title": "No Source",
            "url": "https://example.com/nosrc",
            "published_at": "2026-01-22T05:01:00+00:00"
        }]
        """

        let data = try #require(json.data(using: .utf8))
        let articles = try decoder.decode([SupabaseArticle].self, from: data)
        let article = articles[0].toArticle()

        #expect(article.source.name == "Unknown")
    }
}

// MARK: - Supabase Search Result Contract Tests

@Suite("Supabase Search Result Contract Tests")
struct SupabaseSearchResultContractTests {
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    @Test("Decodes full search result with all fields")
    func decodesFullSearchResult() throws {
        let json = """
        [{
            "id": "search-001",
            "title": "Search Result Article",
            "summary": "Found via search",
            "content": "Full search result content",
            "url": "https://example.com/search",
            "image_url": "https://example.com/search.jpg",
            "published_at": "2026-01-22T05:01:00+00:00",
            "source_name": "BBC",
            "source_slug": "bbc",
            "category_name": "World",
            "category_slug": "world",
            "media_type": null,
            "media_url": null,
            "media_duration": null,
            "media_mime_type": null
        }]
        """

        let data = try #require(json.data(using: .utf8))
        let results = try decoder.decode([SupabaseSearchResult].self, from: data)

        #expect(results.count == 1)
        let result = results[0]
        #expect(result.id == "search-001")
        #expect(result.title == "Search Result Article")

        let article = result.toArticle()
        #expect(article.source.name == "BBC")
        #expect(article.category == .world)
    }

    @Test("Search result toArticle maps consistently with SupabaseArticle")
    func searchResultMapsConsistentlyWithArticle() throws {
        let articleJSON = """
        [{
            "id": "consistency-001",
            "title": "Same Article",
            "summary": "Same summary",
            "content": "Same content",
            "url": "https://example.com/same",
            "published_at": "2026-01-22T05:01:00+00:00",
            "source_name": "Reuters",
            "source_slug": "reuters",
            "category_slug": "business"
        }]
        """

        let data = try #require(articleJSON.data(using: .utf8))
        let supabaseArticle = try decoder.decode([SupabaseArticle].self, from: data)[0].toArticle()
        let searchResult = try decoder.decode([SupabaseSearchResult].self, from: data)[0].toArticle()

        #expect(supabaseArticle.id == searchResult.id)
        #expect(supabaseArticle.title == searchResult.title)
        #expect(supabaseArticle.description == searchResult.description)
        #expect(supabaseArticle.content == searchResult.content)
        #expect(supabaseArticle.source.name == searchResult.source.name)
        #expect(supabaseArticle.category == searchResult.category)
    }
}
