import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("SupabaseAPI Tests")
struct SupabaseAPITests {
    @Test("SupabaseAPI articles uses Edge Functions endpoint")
    func articlesUsesEdgeFunctionsEndpoint() {
        let api = SupabaseAPI.articles(language: "en", page: 1, pageSize: 20)

        let path = api.path

        #expect(path.contains("/functions/v1/api-articles"))
    }

    @Test("SupabaseAPI articles path includes pagination parameters")
    func articlesPathIncludesPagination() {
        let api = SupabaseAPI.articles(language: "en", page: 2, pageSize: 20)

        let path = api.path

        #expect(path.contains("/api-articles"))
        #expect(path.contains("offset=20"))
        #expect(path.contains("limit=20"))
        #expect(path.contains("order=published_at.desc"))
    }

    @Test("SupabaseAPI articles page 1 does not include offset")
    func articlesPage1NoOffset() {
        let api = SupabaseAPI.articles(language: "en", page: 1, pageSize: 20)

        let path = api.path

        #expect(!path.contains("offset="))
    }

    @Test("SupabaseAPI articlesByCategory includes category filter")
    func articlesByCategoryIncludesFilter() {
        let api = SupabaseAPI.articlesByCategory(language: "en", category: "technology", page: 1, pageSize: 20)

        let path = api.path

        #expect(path.contains("/api-articles"))
        #expect(path.contains("category_slug=eq.technology"))
    }

    @Test("SupabaseAPI breakingNews uses limit parameter")
    func breakingNewsUsesLimit() {
        let api = SupabaseAPI.breakingNews(language: "en", limit: 10)

        let path = api.path

        #expect(path.contains("/api-articles"))
        #expect(path.contains("limit=10"))
        #expect(path.contains("order=published_at.desc"))
    }

    @Test("SupabaseAPI article includes id filter")
    func articleIncludesIdFilter() {
        let api = SupabaseAPI.article(id: "article-123")

        let path = api.path

        #expect(path.contains("/api-articles"))
        #expect(path.contains("id=eq.article-123"))
        #expect(path.contains("limit=1"))
    }

    @Test("SupabaseAPI search uses dedicated search endpoint with pagination")
    func searchUsesSearchEndpoint() {
        let api = SupabaseAPI.search(query: "swift", page: 1, pageSize: 20)

        let path = api.path

        #expect(path.contains("/functions/v1/api-search"))
        #expect(path.contains("q=swift"))
        #expect(path.contains("limit=20"))
        #expect(!path.contains("offset="))
    }

    @Test("SupabaseAPI search page 2 includes offset")
    func searchPage2IncludesOffset() {
        let api = SupabaseAPI.search(query: "swift", page: 2, pageSize: 20)

        let path = api.path

        #expect(path.contains("/functions/v1/api-search"))
        #expect(path.contains("q=swift"))
        #expect(path.contains("limit=20"))
        #expect(path.contains("offset=20"))
    }

    @Test("SupabaseAPI categories uses dedicated endpoint")
    func categoriesEndpoint() {
        let api = SupabaseAPI.categories

        let path = api.path

        #expect(path.contains("/functions/v1/api-categories"))
    }

    @Test("SupabaseAPI sources uses dedicated endpoint")
    func sourcesEndpoint() {
        let api = SupabaseAPI.sources

        let path = api.path

        #expect(path.contains("/functions/v1/api-sources"))
    }

    @Test("SupabaseAPI uses GET method")
    func usesGetMethod() {
        let articlesAPI = SupabaseAPI.articles(language: "en", page: 1, pageSize: 20)
        let categoryAPI = SupabaseAPI.articlesByCategory(language: "en", category: "tech", page: 1, pageSize: 20)
        let breakingAPI = SupabaseAPI.breakingNews(language: "en", limit: 10)
        let articleAPI = SupabaseAPI.article(id: "test")
        let searchAPI = SupabaseAPI.search(query: "test", page: 1, pageSize: 20)
        let categoriesAPI = SupabaseAPI.categories
        let sourcesAPI = SupabaseAPI.sources

        #expect(articlesAPI.method == .GET)
        #expect(categoryAPI.method == .GET)
        #expect(breakingAPI.method == .GET)
        #expect(articleAPI.method == .GET)
        #expect(searchAPI.method == .GET)
        #expect(categoriesAPI.method == .GET)
        #expect(sourcesAPI.method == .GET)
    }

    @Test("SupabaseAPI task is nil")
    func taskIsNil() {
        let api = SupabaseAPI.articles(language: "en", page: 1, pageSize: 20)

        #expect(api.task == nil)
    }

    @Test("SupabaseAPI header is nil (no auth required)")
    func headerIsNil() {
        let api = SupabaseAPI.articles(language: "en", page: 1, pageSize: 20)

        #expect(api.header == nil)
    }

    // MARK: - Media Endpoint Tests

    @Test("SupabaseAPI media with specific type filters by category slug")
    func mediaWithSpecificType() {
        let api = SupabaseAPI.media(language: "en", type: "videos", page: 1, pageSize: 20)

        let path = api.path

        #expect(path.contains("/api-articles"))
        #expect(path.contains("category_slug=eq.videos"))
        #expect(path.contains("limit=20"))
        #expect(path.contains("order=published_at.desc"))
    }

    @Test("SupabaseAPI media with nil type filters both podcasts and videos")
    func mediaWithNilType() {
        let api = SupabaseAPI.media(language: "en", type: nil, page: 1, pageSize: 20)

        let path = api.path

        #expect(path.contains("/api-articles"))
        #expect(path.contains("in.(podcasts,videos)"))
        #expect(path.contains("limit=20"))
    }

    @Test("SupabaseAPI media page 1 does not include offset")
    func mediaPage1NoOffset() {
        let api = SupabaseAPI.media(language: "en", type: "videos", page: 1, pageSize: 20)

        let path = api.path

        #expect(!path.contains("offset="))
    }

    @Test("SupabaseAPI media page 2 includes offset")
    func mediaPage2IncludesOffset() {
        let api = SupabaseAPI.media(language: "en", type: "videos", page: 2, pageSize: 20)

        let path = api.path

        #expect(path.contains("offset=20"))
    }

    @Test("SupabaseAPI media page 3 with pageSize 10 has offset 20")
    func mediaPage3Offset() {
        let api = SupabaseAPI.media(language: "en", type: "podcasts", page: 3, pageSize: 10)

        let path = api.path

        #expect(path.contains("offset=20"))
        #expect(path.contains("limit=10"))
        #expect(path.contains("category_slug=eq.podcasts"))
    }

    // MARK: - Featured Media Endpoint Tests

    @Test("SupabaseAPI featuredMedia with specific type")
    func featuredMediaWithSpecificType() {
        let api = SupabaseAPI.featuredMedia(language: "en", type: "podcasts", limit: 10)

        let path = api.path

        #expect(path.contains("/api-articles"))
        #expect(path.contains("category_slug=eq.podcasts"))
        #expect(path.contains("limit=10"))
        #expect(path.contains("order=published_at.desc"))
    }

    @Test("SupabaseAPI featuredMedia with nil type filters both types")
    func featuredMediaWithNilType() {
        let api = SupabaseAPI.featuredMedia(language: "en", type: nil, limit: 5)

        let path = api.path

        #expect(path.contains("/api-articles"))
        #expect(path.contains("in.(podcasts,videos)"))
        #expect(path.contains("limit=5"))
    }

    @Test("SupabaseAPI featuredMedia does not include offset")
    func featuredMediaNoOffset() {
        let api = SupabaseAPI.featuredMedia(language: "en", type: "videos", limit: 10)

        let path = api.path

        #expect(!path.contains("offset="))
    }

    // MARK: - Articles by Category Pagination Tests

    @Test("SupabaseAPI articlesByCategory page 3 includes correct offset")
    func articlesByCategoryPage3() {
        let api = SupabaseAPI.articlesByCategory(language: "en", category: "business", page: 3, pageSize: 15)

        let path = api.path

        #expect(path.contains("offset=30"))
        #expect(path.contains("limit=15"))
        #expect(path.contains("category_slug=eq.business"))
    }

    @Test("SupabaseAPI articlesByCategory page 1 does not include offset")
    func articlesByCategoryPage1NoOffset() {
        let api = SupabaseAPI.articlesByCategory(language: "en", category: "science", page: 1, pageSize: 20)

        let path = api.path

        #expect(!path.contains("offset="))
    }

    // MARK: - Debug Property Tests

    @Test("SupabaseAPI debug is true in debug builds")
    func debugPropertyIsTrue() {
        let api = SupabaseAPI.articles(language: "en", page: 1, pageSize: 20)

        #expect(api.debug)
    }

    // MARK: - Media and Featured Media use GET

    @Test("SupabaseAPI media uses GET method")
    func mediaUsesGetMethod() {
        let mediaAPI = SupabaseAPI.media(language: "en", type: "videos", page: 1, pageSize: 20)
        let featuredAPI = SupabaseAPI.featuredMedia(language: "en", type: nil, limit: 10)

        #expect(mediaAPI.method == .GET)
        #expect(featuredAPI.method == .GET)
    }

    @Test("SupabaseAPI media task is nil")
    func mediaTaskIsNil() {
        let api = SupabaseAPI.media(language: "en", type: "videos", page: 1, pageSize: 20)

        #expect(api.task == nil)
    }

    @Test("SupabaseAPI media header is nil")
    func mediaHeaderIsNil() {
        let api = SupabaseAPI.media(language: "en", type: "videos", page: 1, pageSize: 20)

        #expect(api.header == nil)
    }
}
