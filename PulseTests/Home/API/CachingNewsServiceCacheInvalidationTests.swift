import Combine
import Foundation
@testable import Pulse
import Testing

@Suite("CachingNewsService Cache Invalidation Tests")
struct CachingNewsServiceCacheInvalidationTests {
    let mockNewsService: MockNewsService
    let mockCacheStore: MockNewsCacheStore
    let sut: CachingNewsService

    init() {
        mockNewsService = MockNewsService()
        mockCacheStore = MockNewsCacheStore()
        sut = CachingNewsService(wrapping: mockNewsService, cacheStore: mockCacheStore, diskCacheStore: nil)
    }

    @Test("invalidateCache clears all cached data")
    func invalidateCacheClearsAll() {
        let articles = Article.mockArticles
        mockCacheStore.set(
            CacheEntry(data: articles, timestamp: Date()),
            for: .breakingNews(language: "en", country: "us")
        )
        mockCacheStore.set(
            CacheEntry(data: articles, timestamp: Date()),
            for: .topHeadlines(language: "en", country: "us", page: 1)
        )
        mockCacheStore.removeAllCallCount = 0

        sut.invalidateCache()

        #expect(mockCacheStore.removeAllCallCount == 1)
    }

    @Test("invalidateCache for specific keys removes only those keys")
    func invalidateCacheForSpecificKeys() {
        let articles = Article.mockArticles
        let key1 = NewsCacheKey.topHeadlines(language: "en", country: "us", page: 1)
        let key2 = NewsCacheKey.breakingNews(language: "en", country: "us")
        let key3 = NewsCacheKey.categoryHeadlines(language: "en", category: .technology, country: "us", page: 1)

        mockCacheStore.set(CacheEntry(data: articles, timestamp: Date()), for: key1)
        mockCacheStore.set(CacheEntry(data: articles, timestamp: Date()), for: key2)
        mockCacheStore.set(CacheEntry(data: articles, timestamp: Date()), for: key3)
        mockCacheStore.removeCallCount = 0

        sut.invalidateCache(for: [key1, key2])

        #expect(mockCacheStore.removeCallCount == 2)
        #expect(!mockCacheStore.contains(key: key1))
        #expect(!mockCacheStore.contains(key: key2))
        #expect(mockCacheStore.contains(key: key3))
    }

    @Test("invalidateCache for empty keys array does nothing")
    func invalidateCacheForEmptyKeys() {
        mockCacheStore.removeCallCount = 0

        sut.invalidateCache(for: [])

        #expect(mockCacheStore.removeCallCount == 0)
    }
}
