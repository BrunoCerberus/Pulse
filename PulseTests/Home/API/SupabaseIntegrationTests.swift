import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

// MARK: - SupabaseArticle Mapping Tests

@Suite("SupabaseArticle Mapping Tests")
struct SupabaseArticleMappingTests {
    // MARK: - Content/Description Handling

    @Test("Article with both content and summary maps correctly")
    func contentAndSummaryMappedCorrectly() {
        let article = createSupabaseArticle(
            summary: "Short summary for preview",
            content: "Full article content with lots of details..."
        )

        let mapped = article.toArticle()

        // When content exists, summary becomes description
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

        // When only summary exists, use as content, no description (avoids duplication)
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

    // MARK: - Image URL Handling

    @Test("Image URL maps correctly")
    func imageURLMapsCorrectly() {
        let article = createSupabaseArticle(
            imageUrl: "https://example.com/full.jpg"
        )

        let mapped = article.toArticle()

        // Edge Functions use same image for both imageURL and thumbnailURL
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

    // MARK: - Date Parsing

    @Test("Parses ISO8601 date with fractional seconds")
    func parsesDateWithFractionalSeconds() {
        let article = createSupabaseArticle(
            publishedAt: "2024-01-15T10:30:00.000Z"
        )

        let mapped = article.toArticle()

        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents(in: TimeZone(identifier: "UTC")!, from: mapped.publishedAt)

        #expect(components.year == 2024)
        #expect(components.month == 1)
        #expect(components.day == 15)
        #expect(components.hour == 10)
        #expect(components.minute == 30)
    }

    @Test("Parses ISO8601 date without fractional seconds")
    func parsesDateWithoutFractionalSeconds() {
        let article = createSupabaseArticle(
            publishedAt: "2024-06-20T14:45:00Z"
        )

        let mapped = article.toArticle()

        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents(in: TimeZone(identifier: "UTC")!, from: mapped.publishedAt)

        #expect(components.year == 2024)
        #expect(components.month == 6)
        #expect(components.day == 20)
    }

    // MARK: - Source and Category Mapping (Flat Fields)

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

    // MARK: - Helper

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
        categorySlug: String? = "technology"
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
            categorySlug: categorySlug
        )
    }
}

// MARK: - SupabaseAPI Tests (Edge Functions)

@Suite("SupabaseAPI Tests")
struct SupabaseAPITests {
    // MARK: - Path Construction Tests

    @Test("SupabaseAPI articles uses Edge Functions endpoint")
    func articlesUsesEdgeFunctionsEndpoint() {
        let api = SupabaseAPI.articles(page: 1, pageSize: 20)

        let path = api.path

        #expect(path.contains("/functions/v1/api-articles"))
    }

    @Test("SupabaseAPI articles path includes pagination parameters")
    func articlesPathIncludesPagination() {
        let api = SupabaseAPI.articles(page: 2, pageSize: 20)

        let path = api.path

        #expect(path.contains("/api-articles"))
        #expect(path.contains("offset=20")) // page 2 with pageSize 20 = offset 20
        #expect(path.contains("limit=20"))
        #expect(path.contains("order=published_at.desc"))
    }

    @Test("SupabaseAPI articles page 1 does not include offset")
    func articlesPage1NoOffset() {
        let api = SupabaseAPI.articles(page: 1, pageSize: 20)

        let path = api.path

        // Page 1 should not include offset parameter (offset = 0)
        #expect(!path.contains("offset="))
    }

    @Test("SupabaseAPI articlesByCategory includes category filter")
    func articlesByCategoryIncludesFilter() {
        let api = SupabaseAPI.articlesByCategory(category: "technology", page: 1, pageSize: 20)

        let path = api.path

        #expect(path.contains("/api-articles"))
        #expect(path.contains("category_slug=eq.technology"))
    }

    @Test("SupabaseAPI breakingNews uses limit parameter")
    func breakingNewsUsesLimit() {
        let api = SupabaseAPI.breakingNews(limit: 10)

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
        // Page 1 should not include offset
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
        let articlesAPI = SupabaseAPI.articles(page: 1, pageSize: 20)
        let categoryAPI = SupabaseAPI.articlesByCategory(category: "tech", page: 1, pageSize: 20)
        let breakingAPI = SupabaseAPI.breakingNews(limit: 10)
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
        let api = SupabaseAPI.articles(page: 1, pageSize: 20)

        #expect(api.task == nil)
    }

    @Test("SupabaseAPI header is nil (no auth required)")
    func headerIsNil() {
        let api = SupabaseAPI.articles(page: 1, pageSize: 20)

        #expect(api.header == nil)
    }
}

// MARK: - Live Service Protocol Conformance Tests

@Suite("Live Services Protocol Conformance Tests")
struct LiveServicesProtocolTests {
    @Test("LiveNewsService conforms to NewsService protocol")
    func liveNewsServiceConformance() {
        let service = LiveNewsService()
        #expect(service is NewsService)
    }

    @Test("LiveSearchService conforms to SearchService protocol")
    func liveSearchServiceConformance() {
        let service = LiveSearchService()
        #expect(service is SearchService)
    }

    @Test("LiveNewsService fetchTopHeadlines returns correct publisher type")
    func newsServiceFetchTopHeadlinesType() {
        let service = LiveNewsService()
        let publisher = service.fetchTopHeadlines(country: "us", page: 1)
        let typeCheck: AnyPublisher<[Article], Error> = publisher
        #expect(typeCheck is AnyPublisher<[Article], Error>)
    }

    @Test("LiveSearchService search returns correct publisher type")
    func searchServiceSearchType() {
        let service = LiveSearchService()
        let publisher = service.search(query: "test", page: 1, sortBy: "relevance")
        let typeCheck: AnyPublisher<[Article], Error> = publisher
        #expect(typeCheck is AnyPublisher<[Article], Error>)
    }
}
