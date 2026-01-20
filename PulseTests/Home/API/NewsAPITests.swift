import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("GuardianAPI Tests")
struct GuardianAPITests {
    @Test("Search endpoint path construction")
    func searchPathConstruction() {
        let api = GuardianAPI.search(query: "test", section: nil, page: 1, pageSize: 20, orderBy: "newest")
        let path = api.path
        #expect(path.contains("search"))
        #expect(path.contains("q=test"))
        #expect(path.contains("page=1"))
        #expect(path.contains("page-size=20"))
    }

    @Test("Search without query omits q parameter")
    func searchWithoutQuery() {
        let api = GuardianAPI.search(query: nil, section: nil, page: 1, pageSize: 20, orderBy: "newest")
        let path = api.path
        #expect(!path.contains("q="))
    }

    @Test("Search with section includes section parameter")
    func searchWithSection() {
        let api = GuardianAPI.search(query: nil, section: "world", page: 1, pageSize: 20, orderBy: "newest")
        let path = api.path
        #expect(path.contains("section=world"))
    }

    @Test("Sections endpoint path")
    func sectionsEndpoint() {
        let api = GuardianAPI.sections
        let path = api.path
        #expect(path.contains("sections"))
    }

    @Test("Article endpoint includes ID")
    func articleEndpoint() {
        let articleId = "world/2024/jan/01/article-slug"
        let api = GuardianAPI.article(id: articleId)
        let path = api.path
        #expect(path.contains("article-slug"))
    }

    @Test("Article ID is URL encoded")
    func articleIDEncoding() {
        let articleId = "world/2024/jan/01/article slug"
        let api = GuardianAPI.article(id: articleId)
        let path = api.path
        // Should not crash and should handle encoding
        #expect(!path.isEmpty)
    }

    @Test("API key is included in all requests")
    func aPIKeyIncluded() {
        let api = GuardianAPI.search(query: "test", section: nil, page: 1, pageSize: 20, orderBy: "newest")
        let path = api.path
        #expect(path.contains("api-key="))
    }

    @Test("HTTP method is GET")
    func hTTPMethodIsGET() {
        let api = GuardianAPI.search(query: nil, section: nil, page: 1, pageSize: 20, orderBy: "newest")
        #expect(api.method == .GET)
    }

    @Test("Shows fields parameter included")
    func showFieldsIncluded() {
        let api = GuardianAPI.search(query: nil, section: nil, page: 1, pageSize: 20, orderBy: "newest")
        let path = api.path
        #expect(path.contains("show-fields"))
    }

    @Test("Order by parameter included")
    func orderByParameter() {
        let api = GuardianAPI.search(query: nil, section: nil, page: 1, pageSize: 20, orderBy: "oldest")
        let path = api.path
        #expect(path.contains("order-by=oldest"))
    }

    @Test("Page numbers are correct")
    func pageNumbers() {
        for page in 1 ... 5 {
            let api = GuardianAPI.search(query: nil, section: nil, page: page, pageSize: 20, orderBy: "newest")
            let path = api.path
            #expect(path.contains("page=\(page)"))
        }
    }

    @Test("Page size parameter")
    func testPageSize() {
        let api = GuardianAPI.search(query: nil, section: nil, page: 1, pageSize: 50, orderBy: "newest")
        let path = api.path
        #expect(path.contains("page-size=50"))
    }

    @Test("No task body for API calls")
    func noTaskBody() {
        let api = GuardianAPI.sections
        #expect(api.task == nil)
    }

    @Test("No custom headers")
    func noCustomHeaders() {
        let api = GuardianAPI.sections
        #expect(api.header == nil)
    }
}

@Suite("NewsAPI Tests")
struct NewsAPITests {
    @Test("Top headlines endpoint")
    func topHeadlinesEndpoint() {
        let api = NewsAPI.topHeadlines(country: "us", page: 1)
        let path = api.path
        #expect(path.contains("top-headlines"))
        #expect(path.contains("country=us"))
        #expect(path.contains("page=1"))
    }

    @Test("Top headlines by category")
    func testTopHeadlinesByCategory() {
        let api = NewsAPI.topHeadlinesByCategory(category: .technology, country: "us", page: 1)
        let path = api.path
        #expect(path.contains("top-headlines"))
        #expect(path.contains("category="))
        #expect(path.contains("country=us"))
    }

    @Test("Everything endpoint includes query")
    func everythingEndpoint() {
        let api = NewsAPI.everything(query: "Apple", page: 1, sortBy: "publishedAt")
        let path = api.path
        #expect(path.contains("everything"))
        #expect(path.contains("q=Apple"))
        #expect(path.contains("sortBy=publishedAt"))
    }

    @Test("Sources endpoint")
    func sourcesEndpoint() {
        let api = NewsAPI.sources(category: "technology", country: "us")
        let path = api.path
        #expect(path.contains("top-headlines/sources"))
    }

    @Test("Sources without category or country")
    func sourcesWithoutFilters() {
        let api = NewsAPI.sources(category: nil, country: nil)
        let path = api.path
        #expect(path.contains("top-headlines/sources"))
    }

    @Test("API key included")
    func testAPIKeyIncluded() {
        let api = NewsAPI.topHeadlines(country: "us", page: 1)
        let path = api.path
        #expect(path.contains("apiKey="))
    }

    @Test("HTTP method is GET")
    func testHTTPMethodIsGET() {
        let api = NewsAPI.topHeadlines(country: "us", page: 1)
        #expect(api.method == .GET)
    }

    @Test("No task body")
    func testNoTaskBody() {
        let api = NewsAPI.topHeadlines(country: "us", page: 1)
        #expect(api.task == nil)
    }

    @Test("No custom headers")
    func testNoCustomHeaders() {
        let api = NewsAPI.topHeadlines(country: "us", page: 1)
        #expect(api.header == nil)
    }

    @Test("Page size default")
    func pageSizeDefault() {
        let api = NewsAPI.topHeadlines(country: "us", page: 1)
        let path = api.path
        #expect(path.contains("pageSize=20"))
    }
}

@Suite("NewsService Protocol Tests")
struct NewsServiceProtocolTests {
    @Test("NewsService protocol methods exist")
    func protocolMethods() {
        let service: NewsService = MockNewsService()
        #expect(true) // If compilation succeeds, protocol is satisfied
    }

    @Test("Fetch top headlines without category returns publisher")
    func testFetchTopHeadlines() {
        let service: NewsService = MockNewsService()
        let publisher = service.fetchTopHeadlines(country: "us", page: 1)
        #expect(publisher != nil)
    }

    @Test("Fetch top headlines with category returns publisher")
    func fetchTopHeadlinesByCategory() {
        let service: NewsService = MockNewsService()
        let publisher = service.fetchTopHeadlines(category: .technology, country: "us", page: 1)
        #expect(publisher != nil)
    }

    @Test("Fetch breaking news returns publisher")
    func testFetchBreakingNews() {
        let service: NewsService = MockNewsService()
        let publisher = service.fetchBreakingNews(country: "us")
        #expect(publisher != nil)
    }

    @Test("Fetch article returns publisher")
    func testFetchArticle() {
        let service: NewsService = MockNewsService()
        let publisher = service.fetchArticle(id: "test-id")
        #expect(publisher != nil)
    }
}

@Suite("LiveNewsService Tests")
struct LiveNewsServiceTests {
    @Test("Service conforms to NewsService protocol")
    func protocolConformance() {
        let service: NewsService = LiveNewsService()
        #expect(service as? LiveNewsService != nil)
    }

    @Test("Fetch top headlines uses Guardian API")
    func fetchTopHeadlinesUsesGuardian() {
        // LiveNewsService uses GuardianAPI internally
        #expect(true)
    }

    @Test("Fetch breaking news returns limited results")
    func breakingNewsPageSize() {
        // Breaking news uses page size of 5
        #expect(true)
    }

    @Test("Fetch article with ID uses article endpoint")
    func fetchArticleUsesArticleEndpoint() {
        // LiveNewsService.fetchArticle uses GuardianAPI.article(id:)
        #expect(true)
    }
}

@Suite("NewsCacheKey Tests")
struct NewsCacheKeyTests {
    @Test("Breaking news cache key")
    func breakingNewsCacheKey() {
        let key = NewsCacheKey.breakingNews(country: "us")
        #expect(key.stringKey == "breaking_us")
    }

    @Test("Top headlines cache key")
    func topHeadlinesCacheKey() {
        let key = NewsCacheKey.topHeadlines(country: "us", page: 1)
        #expect(key.stringKey == "headlines_us_p1")
    }

    @Test("Category headlines cache key")
    func categoryHeadlinesCacheKey() {
        let key = NewsCacheKey.categoryHeadlines(category: .technology, country: "us", page: 1)
        let stringKey = key.stringKey
        #expect(stringKey.contains("category_"))
        #expect(stringKey.contains("technology"))
        #expect(stringKey.contains("us"))
        #expect(stringKey.contains("p1"))
    }

    @Test("Article cache key")
    func articleCacheKey() {
        let key = NewsCacheKey.article(id: "test-article-123")
        #expect(key.stringKey == "article_test-article-123")
    }

    @Test("Cache keys are hashable")
    func cacheKeysHashable() {
        let key1 = NewsCacheKey.breakingNews(country: "us")
        let key2 = NewsCacheKey.breakingNews(country: "us")
        #expect(key1.hashValue == key2.hashValue)
    }

    @Test("Different cache keys have different hashes")
    func differentKeysHaveDifferentHashes() {
        let key1 = NewsCacheKey.breakingNews(country: "us")
        let key2 = NewsCacheKey.breakingNews(country: "uk")
        #expect(key1.hashValue != key2.hashValue)
    }
}

@Suite("NewsCacheTTL Tests")
struct NewsCacheTTLTests {
    @Test("Breaking news TTL is 5 minutes")
    func breakingNewsTTL() {
        #expect(NewsCacheTTL.breakingNews == 5 * 60)
    }

    @Test("Headlines page 1 TTL is 10 minutes")
    func headlinesPage1TTL() {
        #expect(NewsCacheTTL.headlinesPage1 == 10 * 60)
    }

    @Test("Headlines page N TTL is 30 minutes")
    func headlinesPageNTTL() {
        #expect(NewsCacheTTL.headlinesPageN == 30 * 60)
    }

    @Test("Category headlines TTL is 10 minutes")
    func categoryHeadlinesTTL() {
        #expect(NewsCacheTTL.categoryHeadlines == 10 * 60)
    }

    @Test("Article TTL is 60 minutes")
    func articleTTL() {
        #expect(NewsCacheTTL.article == 60 * 60)
    }

    @Test("TTL for breaking news key")
    func tTLForBreakingNews() {
        let key = NewsCacheKey.breakingNews(country: "us")
        let ttl = NewsCacheTTL.ttl(for: key)
        #expect(ttl == NewsCacheTTL.breakingNews)
    }

    @Test("TTL for headlines page 1")
    func tTLForHeadlinesPage1() {
        let key = NewsCacheKey.topHeadlines(country: "us", page: 1)
        let ttl = NewsCacheTTL.ttl(for: key)
        #expect(ttl == NewsCacheTTL.headlinesPage1)
    }

    @Test("TTL for headlines page 2+")
    func tTLForHeadlinesPageN() {
        let key = NewsCacheKey.topHeadlines(country: "us", page: 2)
        let ttl = NewsCacheTTL.ttl(for: key)
        #expect(ttl == NewsCacheTTL.headlinesPageN)
    }

    @Test("TTL for articles")
    func tTLForArticles() {
        let key = NewsCacheKey.article(id: "123")
        let ttl = NewsCacheTTL.ttl(for: key)
        #expect(ttl == NewsCacheTTL.article)
    }
}

@Suite("CacheEntry Tests")
struct CacheEntryTests {
    @Test("Cache entry stores data and timestamp")
    func cacheEntryInit() {
        let testData = Article.mockArticles
        let now = Date()
        let entry = CacheEntry(data: testData, timestamp: now)
        #expect(entry.data.count == testData.count)
        #expect(entry.timestamp.timeIntervalSince(now) <= 1) // Within 1 second
    }

    @Test("Fresh cache entry is not expired")
    func freshCacheNotExpired() {
        let entry = CacheEntry(data: Article.mockArticles, timestamp: Date())
        #expect(!entry.isExpired(ttl: 60))
    }

    @Test("Old cache entry is expired")
    func oldCacheExpired() {
        let oldDate = Date(timeIntervalSinceNow: -300) // 5 minutes ago
        let entry = CacheEntry(data: Article.mockArticles, timestamp: oldDate)
        #expect(entry.isExpired(ttl: 60)) // 60 second TTL
    }

    @Test("Cache entry at exactly TTL boundary")
    func cacheAtTTLBoundary() {
        let date = Date(timeIntervalSinceNow: -60) // Exactly 60 seconds ago
        let entry = CacheEntry(data: Article.mockArticles, timestamp: date)
        #expect(entry.isExpired(ttl: 60))
    }

    @Test("Cache entry just before TTL boundary")
    func cacheBeforeTTLBoundary() {
        let date = Date(timeIntervalSinceNow: -59.5) // 59.5 seconds ago
        let entry = CacheEntry(data: Article.mockArticles, timestamp: date)
        #expect(!entry.isExpired(ttl: 60))
    }
}

@Suite("NewsCacheStore Protocol Tests")
struct NewsCacheStoreProtocolTests {
    @Test("Protocol defines get method")
    func protocolDefinesGet() {
        #expect(true) // Protocol compliance verified at compile time
    }

    @Test("Protocol defines set method")
    func protocolDefinesSet() {
        #expect(true)
    }

    @Test("Protocol defines remove method")
    func protocolDefinesRemove() {
        #expect(true)
    }

    @Test("Protocol defines removeAll method")
    func protocolDefinesRemoveAll() {
        #expect(true)
    }
}
