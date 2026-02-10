import Foundation
@testable import Pulse
import Testing

// MARK: - LiveNewsCacheStore Tests

@Suite("LiveNewsCacheStore Tests")
struct LiveNewsCacheStoreTests {
    let sut: LiveNewsCacheStore

    init() {
        sut = LiveNewsCacheStore()
    }

    @Test("get returns nil for empty cache")
    func getReturnsNilForEmptyCache() {
        let result: CacheEntry<[Article]>? = sut.get(for: .breakingNews(country: "us"))
        #expect(result == nil)
    }

    @Test("set and get round-trips article array")
    func setAndGetRoundTrips() {
        let articles = Article.mockArticles
        let entry = CacheEntry(data: articles, timestamp: Date())
        let key = NewsCacheKey.topHeadlines(country: "us", page: 1)

        sut.set(entry, for: key)

        let retrieved: CacheEntry<[Article]>? = sut.get(for: key)
        #expect(retrieved != nil)
        #expect(retrieved?.data.count == articles.count)
        #expect(retrieved?.data.first?.id == articles.first?.id)
    }

    @Test("set and get round-trips single article")
    func setAndGetSingleArticle() {
        let article = Article.mockArticles[0]
        let entry = CacheEntry(data: article, timestamp: Date())
        let key = NewsCacheKey.article(id: article.id)

        sut.set(entry, for: key)

        let retrieved: CacheEntry<Article>? = sut.get(for: key)
        #expect(retrieved != nil)
        #expect(retrieved?.data.id == article.id)
    }

    @Test("remove deletes specific key")
    func removeDeletesSpecificKey() {
        let articles = Article.mockArticles
        let key1 = NewsCacheKey.breakingNews(country: "us")
        let key2 = NewsCacheKey.topHeadlines(country: "us", page: 1)

        sut.set(CacheEntry(data: articles, timestamp: Date()), for: key1)
        sut.set(CacheEntry(data: articles, timestamp: Date()), for: key2)

        sut.remove(for: key1)

        let result1: CacheEntry<[Article]>? = sut.get(for: key1)
        let result2: CacheEntry<[Article]>? = sut.get(for: key2)

        #expect(result1 == nil)
        #expect(result2 != nil)
    }

    @Test("removeAll clears entire cache")
    func removeAllClearsCache() {
        let articles = Article.mockArticles
        sut.set(CacheEntry(data: articles, timestamp: Date()), for: .breakingNews(country: "us"))
        sut.set(CacheEntry(data: articles, timestamp: Date()), for: .topHeadlines(country: "us", page: 1))

        sut.removeAll()

        let result1: CacheEntry<[Article]>? = sut.get(for: .breakingNews(country: "us"))
        let result2: CacheEntry<[Article]>? = sut.get(for: .topHeadlines(country: "us", page: 1))

        #expect(result1 == nil)
        #expect(result2 == nil)
    }

    @Test("get returns nil for wrong type cast")
    func getReturnsNilForWrongType() {
        let articles = Article.mockArticles
        let key = NewsCacheKey.topHeadlines(country: "us", page: 1)
        sut.set(CacheEntry(data: articles, timestamp: Date()), for: key)

        // Try to retrieve as single article instead of array
        let result: CacheEntry<Article>? = sut.get(for: key)
        #expect(result == nil)
    }

    @Test("different keys store independently")
    func differentKeysStoreIndependently() {
        let articles1 = Array(Article.mockArticles.prefix(1))
        let articles2 = Article.mockArticles
        let key1 = NewsCacheKey.topHeadlines(country: "us", page: 1)
        let key2 = NewsCacheKey.topHeadlines(country: "us", page: 2)

        sut.set(CacheEntry(data: articles1, timestamp: Date()), for: key1)
        sut.set(CacheEntry(data: articles2, timestamp: Date()), for: key2)

        let result1: CacheEntry<[Article]>? = sut.get(for: key1)
        let result2: CacheEntry<[Article]>? = sut.get(for: key2)

        #expect(result1?.data.count == 1)
        #expect(result2?.data.count == articles2.count)
    }

    @Test("category headlines use distinct cache keys")
    func categoryHeadlinesDistinctKeys() {
        let techArticles = Article.mockArticles.filter { $0.category == .technology }
        let sportsArticles = Article.mockArticles.filter { $0.category == .sports }
        let techKey = NewsCacheKey.categoryHeadlines(category: .technology, country: "us", page: 1)
        let sportsKey = NewsCacheKey.categoryHeadlines(category: .sports, country: "us", page: 1)

        sut.set(CacheEntry(data: techArticles, timestamp: Date()), for: techKey)
        sut.set(CacheEntry(data: sportsArticles, timestamp: Date()), for: sportsKey)

        let techResult: CacheEntry<[Article]>? = sut.get(for: techKey)
        let sportsResult: CacheEntry<[Article]>? = sut.get(for: sportsKey)

        #expect(techResult?.data.count == techArticles.count)
        #expect(sportsResult?.data.count == sportsArticles.count)
    }
}

// MARK: - NewsCacheTTL Tests

@Suite("NewsCacheTTL Tests")
struct NewsCacheTTLTests {
    @Test("Default TTL is 10 minutes")
    func defaultTTLIsTenMinutes() {
        #expect(NewsCacheTTL.default == 600)
    }
}

// MARK: - Additional CacheEntry Tests

@Suite("CacheEntry Extended Tests")
struct CacheEntryExtendedTests {
    @Test("CacheEntry stores timestamp correctly")
    func storesTimestamp() {
        let now = Date()
        let entry = CacheEntry(data: "test", timestamp: now)
        #expect(entry.timestamp == now)
    }

    @Test("CacheEntry stores data correctly")
    func storesData() {
        let entry = CacheEntry(data: [1, 2, 3], timestamp: Date())
        #expect(entry.data == [1, 2, 3])
    }

    @Test("CacheEntry with future timestamp is not expired")
    func futureTimestampNotExpired() {
        let futureDate = Date().addingTimeInterval(100)
        let entry = CacheEntry(data: "test", timestamp: futureDate)
        #expect(!entry.isExpired(ttl: 60))
    }
}

// MARK: - Additional NewsCacheKey Tests

@Suite("NewsCacheKey Extended Tests")
struct NewsCacheKeyExtendedTests {
    @Test("Article key contains article id")
    func articleKeyContainsId() {
        let key = NewsCacheKey.article(id: "my-article-123")
        #expect(key.stringKey.contains("my-article-123"))
    }

    @Test("Breaking news key contains country")
    func breakingNewsKeyContainsCountry() {
        let key = NewsCacheKey.breakingNews(country: "gb")
        #expect(key.stringKey.contains("gb"))
    }

    @Test("Category key contains category name")
    func categoryKeyContainsCategoryName() {
        let key = NewsCacheKey.categoryHeadlines(category: .technology, country: "us", page: 1)
        #expect(key.stringKey.contains("technology"))
    }

    @Test("Headlines key contains page number")
    func headlinesKeyContainsPage() {
        let key = NewsCacheKey.topHeadlines(country: "us", page: 3)
        #expect(key.stringKey.contains("3"))
    }
}
