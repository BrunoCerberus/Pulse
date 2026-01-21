import Combine
import Foundation
@testable import Pulse
import Testing

@Suite("CachingNewsService Tests")
struct CachingNewsServiceTests {
    let mockNewsService: MockNewsService
    let mockCacheStore: MockNewsCacheStore
    let sut: CachingNewsService

    init() {
        mockNewsService = MockNewsService()
        mockCacheStore = MockNewsCacheStore()
        sut = CachingNewsService(wrapping: mockNewsService, cacheStore: mockCacheStore)
    }

    // MARK: - Top Headlines Tests

    @Test("fetchTopHeadlines returns cached data when available and not expired")
    func fetchTopHeadlinesCacheHit() async throws {
        // Setup: Pre-populate cache with articles
        let cachedArticles = Article.mockArticles
        let cacheKey = NewsCacheKey.topHeadlines(country: "us", page: 1)
        let entry = CacheEntry(data: cachedArticles, timestamp: Date())
        mockCacheStore.set(entry, for: cacheKey)

        // Reset call counts after setup
        mockCacheStore.getCallCount = 0
        mockCacheStore.setCallCount = 0

        var receivedArticles: [Article] = []
        var cancellables = Set<AnyCancellable>()

        sut.fetchTopHeadlines(country: "us", page: 1)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { articles in
                    receivedArticles = articles
                }
            )
            .store(in: &cancellables)

        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(receivedArticles == cachedArticles)
        #expect(mockCacheStore.getCallCount == 1)
        // Should NOT call set since it was a cache hit
        #expect(mockCacheStore.setCallCount == 0)
    }

    @Test("fetchTopHeadlines fetches from network when cache is empty")
    func fetchTopHeadlinesCacheMiss() async throws {
        let networkArticles = Article.mockArticles
        mockNewsService.topHeadlinesResult = .success(networkArticles)

        var receivedArticles: [Article] = []
        var cancellables = Set<AnyCancellable>()

        sut.fetchTopHeadlines(country: "us", page: 1)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { articles in
                    receivedArticles = articles
                }
            )
            .store(in: &cancellables)

        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(receivedArticles == networkArticles)
        #expect(mockCacheStore.getCallCount == 1)
        #expect(mockCacheStore.setCallCount == 1)

        // Verify the data was cached
        let cacheKey = NewsCacheKey.topHeadlines(country: "us", page: 1)
        #expect(mockCacheStore.contains(key: cacheKey))
    }

    @Test("fetchTopHeadlines fetches from network when cache is expired")
    func fetchTopHeadlinesExpiredCache() async throws {
        // Setup: Pre-populate cache with expired entry (timestamp in the past)
        let expiredTimestamp = Date().addingTimeInterval(-NewsCacheTTL.headlinesPage1 - 1)
        let cachedArticles = [Article.mockArticles[0]]
        let cacheKey = NewsCacheKey.topHeadlines(country: "us", page: 1)
        let entry = CacheEntry(data: cachedArticles, timestamp: expiredTimestamp)
        mockCacheStore.set(entry, for: cacheKey)

        // Network returns different articles
        let networkArticles = Article.mockArticles
        mockNewsService.topHeadlinesResult = .success(networkArticles)

        mockCacheStore.getCallCount = 0
        mockCacheStore.setCallCount = 0

        var receivedArticles: [Article] = []
        var cancellables = Set<AnyCancellable>()

        sut.fetchTopHeadlines(country: "us", page: 1)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { articles in
                    receivedArticles = articles
                }
            )
            .store(in: &cancellables)

        try await Task.sleep(nanoseconds: 100_000_000)

        // Should return network articles, not cached
        #expect(receivedArticles == networkArticles)
        // Should update cache with fresh data
        #expect(mockCacheStore.setCallCount == 1)
    }

    // MARK: - Breaking News Tests

    @Test("fetchBreakingNews returns cached data when available")
    func fetchBreakingNewsCacheHit() async throws {
        let cachedArticles = Array(Article.mockArticles.prefix(3))
        let cacheKey = NewsCacheKey.breakingNews(country: "us")
        let entry = CacheEntry(data: cachedArticles, timestamp: Date())
        mockCacheStore.set(entry, for: cacheKey)
        mockCacheStore.getCallCount = 0

        var receivedArticles: [Article] = []
        var cancellables = Set<AnyCancellable>()

        sut.fetchBreakingNews(country: "us")
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { articles in
                    receivedArticles = articles
                }
            )
            .store(in: &cancellables)

        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(receivedArticles == cachedArticles)
        #expect(mockCacheStore.getCallCount == 1)
    }

    @Test("fetchBreakingNews fetches from network when cache is empty")
    func fetchBreakingNewsCacheMiss() async throws {
        let networkArticles = Array(Article.mockArticles.prefix(3))
        mockNewsService.breakingNewsResult = .success(networkArticles)

        var receivedArticles: [Article] = []
        var cancellables = Set<AnyCancellable>()

        sut.fetchBreakingNews(country: "us")
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { articles in
                    receivedArticles = articles
                }
            )
            .store(in: &cancellables)

        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(receivedArticles == networkArticles)
        #expect(mockCacheStore.setCallCount == 1)
    }

    // MARK: - Category Headlines Tests

    @Test("fetchTopHeadlines with category returns cached data when available")
    func fetchCategoryHeadlinesCacheHit() async throws {
        let cachedArticles = Article.mockArticles
        let cacheKey = NewsCacheKey.categoryHeadlines(category: .technology, country: "us", page: 1)
        let entry = CacheEntry(data: cachedArticles, timestamp: Date())
        mockCacheStore.set(entry, for: cacheKey)
        mockCacheStore.getCallCount = 0

        var receivedArticles: [Article] = []
        var cancellables = Set<AnyCancellable>()

        sut.fetchTopHeadlines(category: .technology, country: "us", page: 1)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { articles in
                    receivedArticles = articles
                }
            )
            .store(in: &cancellables)

        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(receivedArticles == cachedArticles)
        #expect(mockCacheStore.getCallCount == 1)
    }

    // MARK: - Article Tests

    @Test("fetchArticle returns cached article when available")
    func fetchArticleCacheHit() async throws {
        let cachedArticle = Article.mockArticles[0]
        let cacheKey = NewsCacheKey.article(id: cachedArticle.id)
        let entry = CacheEntry(data: cachedArticle, timestamp: Date())
        mockCacheStore.set(entry, for: cacheKey)
        mockCacheStore.getCallCount = 0

        var receivedArticle: Article?
        var cancellables = Set<AnyCancellable>()

        sut.fetchArticle(id: cachedArticle.id)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { article in
                    receivedArticle = article
                }
            )
            .store(in: &cancellables)

        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(receivedArticle == cachedArticle)
        #expect(mockCacheStore.getCallCount == 1)
    }

    @Test("fetchArticle fetches from network when cache is empty")
    func fetchArticleCacheMiss() async throws {
        let networkArticle = Article.mockArticles[0]
        mockNewsService.fetchArticleResult = .success(networkArticle)

        var receivedArticle: Article?
        var cancellables = Set<AnyCancellable>()

        sut.fetchArticle(id: networkArticle.id)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { article in
                    receivedArticle = article
                }
            )
            .store(in: &cancellables)

        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(receivedArticle == networkArticle)
        #expect(mockCacheStore.setCallCount == 1)
    }

    // MARK: - Cache Invalidation Tests

    @Test("invalidateCache clears all cached data")
    func invalidateCacheClearsAll() {
        // Pre-populate cache
        let articles = Article.mockArticles
        mockCacheStore.set(CacheEntry(data: articles, timestamp: Date()), for: .breakingNews(country: "us"))
        mockCacheStore.set(CacheEntry(data: articles, timestamp: Date()), for: .topHeadlines(country: "us", page: 1))
        mockCacheStore.removeAllCallCount = 0

        sut.invalidateCache()

        #expect(mockCacheStore.removeAllCallCount == 1)
    }

    @Test("invalidateCache for specific key removes only that key")
    func invalidateCacheForKey() {
        let cacheKey = NewsCacheKey.topHeadlines(country: "us", page: 1)
        let articles = Article.mockArticles
        mockCacheStore.set(CacheEntry(data: articles, timestamp: Date()), for: cacheKey)
        mockCacheStore.removeCallCount = 0

        sut.invalidateCache(for: cacheKey)

        #expect(mockCacheStore.removeCallCount == 1)
        #expect(!mockCacheStore.contains(key: cacheKey))
    }

    @Test("invalidateFreshContent removes headlines but preserves article cache")
    func invalidateFreshContentPreservesArticles() {
        let articles = Article.mockArticles
        let article = articles[0]

        // Pre-populate cache with various content types
        mockCacheStore.set(CacheEntry(data: articles, timestamp: Date()), for: .breakingNews(country: "us"))
        mockCacheStore.set(CacheEntry(data: articles, timestamp: Date()), for: .topHeadlines(country: "us", page: 1))
        mockCacheStore.set(CacheEntry(data: articles, timestamp: Date()), for: .topHeadlines(country: "us", page: 2))
        mockCacheStore.set(
            CacheEntry(data: articles, timestamp: Date()),
            for: .categoryHeadlines(category: .technology, country: "us", page: 1)
        )
        mockCacheStore.set(CacheEntry(data: article, timestamp: Date()), for: .article(id: article.id))

        mockCacheStore.removeMatchingCallCount = 0

        sut.invalidateFreshContent()

        // Should call removeMatching once
        #expect(mockCacheStore.removeMatchingCallCount == 1)

        // Headlines should be removed
        #expect(!mockCacheStore.contains(key: .breakingNews(country: "us")))
        #expect(!mockCacheStore.contains(key: .topHeadlines(country: "us", page: 1)))
        #expect(!mockCacheStore.contains(key: .topHeadlines(country: "us", page: 2)))
        #expect(!mockCacheStore.contains(key: .categoryHeadlines(category: .technology, country: "us", page: 1)))

        // Article should be preserved
        #expect(mockCacheStore.contains(key: .article(id: article.id)))
    }

    @Test("invalidateFreshContent on empty cache does not crash")
    func invalidateFreshContentOnEmptyCache() {
        mockCacheStore.removeMatchingCallCount = 0

        // Should not crash on empty cache
        sut.invalidateFreshContent()

        #expect(mockCacheStore.removeMatchingCallCount == 1)
    }

    @Test("invalidateFreshContent removes all headline types")
    func invalidateFreshContentRemovesAllHeadlineTypes() {
        let articles = Article.mockArticles

        // Add multiple headline types
        mockCacheStore.set(CacheEntry(data: articles, timestamp: Date()), for: .breakingNews(country: "us"))
        mockCacheStore.set(CacheEntry(data: articles, timestamp: Date()), for: .breakingNews(country: "uk"))
        mockCacheStore.set(CacheEntry(data: articles, timestamp: Date()), for: .topHeadlines(country: "us", page: 1))
        mockCacheStore.set(CacheEntry(data: articles, timestamp: Date()), for: .topHeadlines(country: "uk", page: 1))
        mockCacheStore.set(
            CacheEntry(data: articles, timestamp: Date()),
            for: .categoryHeadlines(category: .sports, country: "us", page: 1)
        )
        mockCacheStore.set(
            CacheEntry(data: articles, timestamp: Date()),
            for: .categoryHeadlines(category: .business, country: "us", page: 1)
        )

        sut.invalidateFreshContent()

        // All headline types should be removed
        #expect(!mockCacheStore.contains(key: .breakingNews(country: "us")))
        #expect(!mockCacheStore.contains(key: .breakingNews(country: "uk")))
        #expect(!mockCacheStore.contains(key: .topHeadlines(country: "us", page: 1)))
        #expect(!mockCacheStore.contains(key: .topHeadlines(country: "uk", page: 1)))
        #expect(!mockCacheStore.contains(key: .categoryHeadlines(category: .sports, country: "us", page: 1)))
        #expect(!mockCacheStore.contains(key: .categoryHeadlines(category: .business, country: "us", page: 1)))
    }

    @Test("invalidateFreshContent preserves multiple articles")
    func invalidateFreshContentPreservesMultipleArticles() {
        let articles = Article.mockArticles

        // Add multiple articles
        for article in articles {
            mockCacheStore.set(CacheEntry(data: article, timestamp: Date()), for: .article(id: article.id))
        }

        // Add some headlines
        mockCacheStore.set(CacheEntry(data: articles, timestamp: Date()), for: .breakingNews(country: "us"))

        sut.invalidateFreshContent()

        // All articles should be preserved
        for article in articles {
            #expect(mockCacheStore.contains(key: .article(id: article.id)))
        }

        // Headlines should be removed
        #expect(!mockCacheStore.contains(key: .breakingNews(country: "us")))
    }

    // MARK: - TTL Tests

    @Test("Page 2+ headlines use longer TTL than page 1")
    func page2HasLongerTTL() {
        let page1TTL = NewsCacheTTL.ttl(for: .topHeadlines(country: "us", page: 1))
        let page2TTL = NewsCacheTTL.ttl(for: .topHeadlines(country: "us", page: 2))

        #expect(page2TTL > page1TTL)
        #expect(page1TTL == NewsCacheTTL.headlinesPage1)
        #expect(page2TTL == NewsCacheTTL.headlinesPageN)
    }

    @Test("Breaking news has shortest TTL")
    func breakingNewsHasShortestTTL() {
        let breakingTTL = NewsCacheTTL.ttl(for: .breakingNews(country: "us"))
        let headlinesTTL = NewsCacheTTL.ttl(for: .topHeadlines(country: "us", page: 1))
        let articleTTL = NewsCacheTTL.ttl(for: .article(id: "test"))

        #expect(breakingTTL < headlinesTTL)
        #expect(breakingTTL < articleTTL)
    }

    @Test("Article has longest TTL")
    func articleHasLongestTTL() {
        let articleTTL = NewsCacheTTL.ttl(for: .article(id: "test"))
        let headlinesTTL = NewsCacheTTL.ttl(for: .topHeadlines(country: "us", page: 2))
        let categoryTTL = NewsCacheTTL.ttl(for: .categoryHeadlines(category: .technology, country: "us", page: 1))

        #expect(articleTTL > headlinesTTL)
        #expect(articleTTL > categoryTTL)
    }
}

// MARK: - Cache Entry Tests

@Suite("CacheEntry Tests")
struct CacheEntryTests {
    @Test("CacheEntry isExpired returns false when within TTL")
    func cacheEntryNotExpired() {
        let entry = CacheEntry(data: "test", timestamp: Date())
        #expect(!entry.isExpired(ttl: 60))
    }

    @Test("CacheEntry isExpired returns true when past TTL")
    func cacheEntryExpired() {
        let pastTimestamp = Date().addingTimeInterval(-61)
        let entry = CacheEntry(data: "test", timestamp: pastTimestamp)
        #expect(entry.isExpired(ttl: 60))
    }

    @Test("CacheEntry isExpired returns true exactly at TTL boundary")
    func cacheEntryAtBoundary() {
        let pastTimestamp = Date().addingTimeInterval(-60)
        let entry = CacheEntry(data: "test", timestamp: pastTimestamp)
        #expect(entry.isExpired(ttl: 60))
    }
}

// MARK: - Cache Key Tests

@Suite("NewsCacheKey Tests")
struct NewsCacheKeyTests {
    @Test("Cache keys generate unique string keys")
    func uniqueStringKeys() {
        let key1 = NewsCacheKey.breakingNews(country: "us")
        let key2 = NewsCacheKey.topHeadlines(country: "us", page: 1)
        let key3 = NewsCacheKey.topHeadlines(country: "us", page: 2)
        let key4 = NewsCacheKey.categoryHeadlines(category: .technology, country: "us", page: 1)
        let key5 = NewsCacheKey.article(id: "test-article")

        let allKeys = [key1.stringKey, key2.stringKey, key3.stringKey, key4.stringKey, key5.stringKey]
        let uniqueKeys = Set(allKeys)

        #expect(allKeys.count == uniqueKeys.count)
    }

    @Test("Same parameters produce same cache key")
    func sameParametersSameKey() {
        let key1 = NewsCacheKey.topHeadlines(country: "us", page: 1)
        let key2 = NewsCacheKey.topHeadlines(country: "us", page: 1)

        #expect(key1.stringKey == key2.stringKey)
        #expect(key1 == key2)
    }

    @Test("Different parameters produce different cache keys")
    func differentParametersDifferentKeys() {
        let key1 = NewsCacheKey.topHeadlines(country: "us", page: 1)
        let key2 = NewsCacheKey.topHeadlines(country: "uk", page: 1)
        let key3 = NewsCacheKey.topHeadlines(country: "us", page: 2)

        #expect(key1.stringKey != key2.stringKey)
        #expect(key1.stringKey != key3.stringKey)
    }
}
