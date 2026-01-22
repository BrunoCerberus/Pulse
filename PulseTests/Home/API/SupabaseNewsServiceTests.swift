import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

// MARK: - SupabaseNewsService Tests

@Suite("SupabaseNewsService Tests")
struct SupabaseNewsServiceTests {
    // MARK: - Initialization Tests

    @Test("SupabaseNewsService can be instantiated")
    func canBeInstantiated() {
        let service = SupabaseNewsService()

        #expect(service is NewsService)
    }

    @Test("SupabaseNewsService accepts fallback service")
    func acceptsFallbackService() {
        let fallback = MockNewsService()
        let service = SupabaseNewsService(fallbackService: fallback)

        #expect(service is NewsService)
    }

    // MARK: - Protocol Conformance Tests

    @Test("fetchTopHeadlines returns correct publisher type")
    func fetchTopHeadlinesReturnsCorrectType() {
        let service = SupabaseNewsService()

        let publisher = service.fetchTopHeadlines(country: "us", page: 1)

        let typeCheck: AnyPublisher<[Article], Error> = publisher
        #expect(typeCheck is AnyPublisher<[Article], Error>)
    }

    @Test("fetchBreakingNews returns correct publisher type")
    func fetchBreakingNewsReturnsCorrectType() {
        let service = SupabaseNewsService()

        let publisher = service.fetchBreakingNews(country: "us")

        let typeCheck: AnyPublisher<[Article], Error> = publisher
        #expect(typeCheck is AnyPublisher<[Article], Error>)
    }

    @Test("fetchTopHeadlines by category returns correct publisher type")
    func fetchTopHeadlinesByCategoryReturnsCorrectType() {
        let service = SupabaseNewsService()

        let publisher = service.fetchTopHeadlines(category: .technology, country: "us", page: 1)

        let typeCheck: AnyPublisher<[Article], Error> = publisher
        #expect(typeCheck is AnyPublisher<[Article], Error>)
    }

    @Test("fetchArticle returns correct publisher type")
    func fetchArticleReturnsCorrectType() {
        let service = SupabaseNewsService()

        let publisher = service.fetchArticle(id: "test-article-id")

        let typeCheck: AnyPublisher<Article, Error> = publisher
        #expect(typeCheck is AnyPublisher<Article, Error>)
    }
}

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

    @Test("Image URLs prioritize full-size for imageURL")
    func imageURLPrioritizesFullSize() {
        let article = createSupabaseArticle(
            imageUrl: "https://example.com/full.jpg",
            thumbnailUrl: "https://example.com/thumb.jpg"
        )

        let mapped = article.toArticle()

        #expect(mapped.imageURL == "https://example.com/full.jpg")
        #expect(mapped.thumbnailURL == "https://example.com/thumb.jpg")
    }

    @Test("Image URL falls back to thumbnail when no full-size available")
    func imageURLFallsBackToThumbnail() {
        let article = createSupabaseArticle(
            imageUrl: nil,
            thumbnailUrl: "https://example.com/thumb.jpg"
        )

        let mapped = article.toArticle()

        #expect(mapped.imageURL == "https://example.com/thumb.jpg")
        #expect(mapped.thumbnailURL == "https://example.com/thumb.jpg")
    }

    @Test("Thumbnail URL does not fallback to full-size image")
    func thumbnailDoesNotFallbackToFullSize() {
        let article = createSupabaseArticle(
            imageUrl: "https://example.com/full.jpg",
            thumbnailUrl: nil
        )

        let mapped = article.toArticle()

        // imageURL should have the full-size
        #expect(mapped.imageURL == "https://example.com/full.jpg")
        // thumbnailURL should NOT fallback to full-size (would defeat optimization)
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

    // MARK: - Source and Category Mapping

    @Test("Source maps correctly")
    func sourceMapsCorrectly() {
        let article = createSupabaseArticle(
            sources: SupabaseSource(
                id: "src-123",
                name: "TechCrunch",
                slug: "techcrunch",
                logoUrl: "https://example.com/logo.png",
                websiteUrl: "https://techcrunch.com"
            )
        )

        let mapped = article.toArticle()

        #expect(mapped.source.id == "techcrunch")
        #expect(mapped.source.name == "TechCrunch")
    }

    @Test("Missing source uses Unknown as name")
    func missingSourceUsesUnknown() {
        let article = createSupabaseArticle(sources: nil)

        let mapped = article.toArticle()

        #expect(mapped.source.name == "Unknown")
    }

    @Test("Category maps to NewsCategory when slug matches")
    func categoryMapsWhenSlugMatches() {
        let article = createSupabaseArticle(
            categories: SupabaseCategory(id: "cat-1", name: "Technology", slug: "technology")
        )

        let mapped = article.toArticle()

        #expect(mapped.category == .technology)
    }

    @Test("Category is nil when slug does not match NewsCategory")
    func categoryNilWhenNoMatch() {
        let article = createSupabaseArticle(
            categories: SupabaseCategory(id: "cat-1", name: "Random", slug: "random-category")
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
        thumbnailUrl: String? = "https://example.com/thumb.jpg",
        author: String? = "Test Author",
        publishedAt: String = "2024-01-15T10:30:00.000Z",
        sources: SupabaseSource? = SupabaseSource(
            id: "src-1",
            name: "Test Source",
            slug: "test-source",
            logoUrl: nil,
            websiteUrl: nil
        ),
        categories: SupabaseCategory? = SupabaseCategory(
            id: "cat-1",
            name: "Technology",
            slug: "technology"
        )
    ) -> SupabaseArticle {
        SupabaseArticle(
            id: id,
            title: title,
            summary: summary,
            content: content,
            url: url,
            imageUrl: imageUrl,
            thumbnailUrl: thumbnailUrl,
            author: author,
            publishedAt: publishedAt,
            sources: sources,
            categories: categories
        )
    }
}

// MARK: - SupabaseAPI Tests

@Suite("SupabaseAPI Tests")
struct SupabaseAPITests {
    // MARK: - Path Construction Tests

    @Test("SupabaseAPI articles path includes pagination parameters")
    func articlesPathIncludesPagination() {
        let api = SupabaseAPI.articles(page: 2, pageSize: 20)

        let path = api.path

        #expect(path.contains("/articles"))
        #expect(path.contains("offset=20")) // page 2 with pageSize 20 = offset 20
        #expect(path.contains("limit=20"))
        #expect(path.contains("order=published_at.desc"))
    }

    @Test("SupabaseAPI articles page 1 has offset 0")
    func articlesPage1HasOffsetZero() {
        let api = SupabaseAPI.articles(page: 1, pageSize: 20)

        let path = api.path

        #expect(path.contains("offset=0"))
    }

    @Test("SupabaseAPI articlesByCategory includes category filter")
    func articlesByCategoryIncludesFilter() {
        let api = SupabaseAPI.articlesByCategory(category: "technology", page: 1, pageSize: 20)

        let path = api.path

        #expect(path.contains("categories.slug=eq.technology"))
        #expect(path.contains("categories!inner"))
    }

    @Test("SupabaseAPI breakingNews includes since filter")
    func breakingNewsIncludesSinceFilter() {
        let api = SupabaseAPI.breakingNews(since: "2024-01-15T00:00:00Z")

        let path = api.path

        #expect(path.contains("published_at=gte.2024-01-15T00:00:00Z"))
        #expect(path.contains("limit=10"))
    }

    @Test("SupabaseAPI article includes id filter")
    func articleIncludesIdFilter() {
        let api = SupabaseAPI.article(id: "article-123")

        let path = api.path

        #expect(path.contains("id=eq.article-123"))
        #expect(path.contains("limit=1"))
    }

    @Test("SupabaseAPI uses GET method")
    func usesGetMethod() {
        let articlesAPI = SupabaseAPI.articles(page: 1, pageSize: 20)
        let categoryAPI = SupabaseAPI.articlesByCategory(category: "tech", page: 1, pageSize: 20)
        let breakingAPI = SupabaseAPI.breakingNews(since: "2024-01-01")
        let articleAPI = SupabaseAPI.article(id: "test")

        #expect(articlesAPI.method == .GET)
        #expect(categoryAPI.method == .GET)
        #expect(breakingAPI.method == .GET)
        #expect(articleAPI.method == .GET)
    }

    @Test("SupabaseAPI task is nil")
    func taskIsNil() {
        let api = SupabaseAPI.articles(page: 1, pageSize: 20)

        #expect(api.task == nil)
    }

    @Test("SupabaseAPI includes select parameter with fields")
    func includesSelectParameter() {
        let api = SupabaseAPI.articles(page: 1, pageSize: 20)

        let path = api.path

        #expect(path.contains("select="))
        #expect(path.contains("title"))
        #expect(path.contains("summary"))
        #expect(path.contains("content"))
        #expect(path.contains("image_url"))
        #expect(path.contains("thumbnail_url"))
    }
}

// MARK: - SupabaseNewsError Tests

@Suite("SupabaseNewsError Tests")
struct SupabaseNewsErrorTests {
    @Test("notConfigured error has correct description")
    func notConfiguredErrorDescription() {
        let error = SupabaseNewsError.notConfigured

        #expect(error.errorDescription == "Supabase backend is not configured")
    }

    @Test("articleNotFound error has correct description")
    func articleNotFoundErrorDescription() {
        let error = SupabaseNewsError.articleNotFound

        #expect(error.errorDescription == "Article not found")
    }
}
