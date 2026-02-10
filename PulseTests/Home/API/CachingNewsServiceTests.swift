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
        let expiredTimestamp = Date().addingTimeInterval(-NewsCacheTTL.default - 1)
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

    // MARK: - Selective Invalidation Tests

    @Test("invalidateCache for specific keys removes only those keys")
    func invalidateCacheForSpecificKeys() {
        let articles = Article.mockArticles
        let key1 = NewsCacheKey.topHeadlines(country: "us", page: 1)
        let key2 = NewsCacheKey.breakingNews(country: "us")
        let key3 = NewsCacheKey.categoryHeadlines(category: .technology, country: "us", page: 1)

        mockCacheStore.set(CacheEntry(data: articles, timestamp: Date()), for: key1)
        mockCacheStore.set(CacheEntry(data: articles, timestamp: Date()), for: key2)
        mockCacheStore.set(CacheEntry(data: articles, timestamp: Date()), for: key3)
        mockCacheStore.removeCallCount = 0

        sut.invalidateCache(for: [key1, key2])

        #expect(mockCacheStore.removeCallCount == 2)
        #expect(!mockCacheStore.contains(key: key1))
        #expect(!mockCacheStore.contains(key: key2))
        #expect(mockCacheStore.contains(key: key3)) // Not invalidated
    }

    @Test("invalidateCache for empty keys array does nothing")
    func invalidateCacheForEmptyKeys() {
        mockCacheStore.removeCallCount = 0

        sut.invalidateCache(for: [])

        #expect(mockCacheStore.removeCallCount == 0)
    }

    // MARK: - Category Headlines Cache Miss

    @Test("fetchTopHeadlines with category fetches from network when cache misses")
    func fetchCategoryHeadlinesCacheMiss() async throws {
        let networkArticles = Article.mockArticles
        mockNewsService.topHeadlinesResult = .success(networkArticles)

        var receivedArticles: [Article] = []
        var cancellables = Set<AnyCancellable>()

        sut.fetchTopHeadlines(category: .science, country: "us", page: 1)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { articles in
                    receivedArticles = articles
                }
            )
            .store(in: &cancellables)

        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(!receivedArticles.isEmpty)
        #expect(mockCacheStore.setCallCount >= 1)

        // Verify the data was cached with correct key
        let cacheKey = NewsCacheKey.categoryHeadlines(category: .science, country: "us", page: 1)
        #expect(mockCacheStore.contains(key: cacheKey))
    }

    // MARK: - Article Cache Expiry

    @Test("fetchArticle fetches from network when cache is expired")
    func fetchArticleExpiredCache() async throws {
        let expiredTimestamp = Date().addingTimeInterval(-NewsCacheTTL.default - 1)
        let cachedArticle = Article.mockArticles[0]
        let cacheKey = NewsCacheKey.article(id: cachedArticle.id)
        let entry = CacheEntry(data: cachedArticle, timestamp: expiredTimestamp)
        mockCacheStore.set(entry, for: cacheKey)

        let networkArticle = Article.mockArticles[1]
        mockNewsService.fetchArticleResult = .success(networkArticle)

        mockCacheStore.getCallCount = 0
        mockCacheStore.setCallCount = 0

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

        // Should return network article, not cached
        #expect(receivedArticle == networkArticle)
        // Should update cache with fresh data
        #expect(mockCacheStore.setCallCount == 1)
    }

    // MARK: - Breaking News Cache Expiry

    @Test("fetchBreakingNews fetches from network when cache is expired")
    func fetchBreakingNewsExpiredCache() async throws {
        let expiredTimestamp = Date().addingTimeInterval(-NewsCacheTTL.default - 1)
        let cachedArticles = Array(Article.mockArticles.prefix(3))
        let cacheKey = NewsCacheKey.breakingNews(country: "us")
        let entry = CacheEntry(data: cachedArticles, timestamp: expiredTimestamp)
        mockCacheStore.set(entry, for: cacheKey)

        let networkArticles = Article.mockArticles
        mockNewsService.breakingNewsResult = .success(networkArticles)

        mockCacheStore.getCallCount = 0
        mockCacheStore.setCallCount = 0

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

    // MARK: - Category Headlines Cache Expiry

    @Test("fetchTopHeadlines with category fetches from network when expired")
    func fetchCategoryHeadlinesExpiredCache() async throws {
        let expiredTimestamp = Date().addingTimeInterval(-NewsCacheTTL.default - 1)
        let cachedArticles = [Article.mockArticles[0]]
        let cacheKey = NewsCacheKey.categoryHeadlines(category: .technology, country: "us", page: 1)
        let entry = CacheEntry(data: cachedArticles, timestamp: expiredTimestamp)
        mockCacheStore.set(entry, for: cacheKey)

        let networkArticles = Article.mockArticles
        mockNewsService.topHeadlinesResult = .success(networkArticles)

        mockCacheStore.getCallCount = 0
        mockCacheStore.setCallCount = 0

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

        #expect(!receivedArticles.isEmpty)
        #expect(mockCacheStore.setCallCount == 1)
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
