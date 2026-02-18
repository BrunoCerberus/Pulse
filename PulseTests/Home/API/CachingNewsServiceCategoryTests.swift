import Combine
import Foundation
@testable import Pulse
import Testing

@Suite("CachingNewsService Category Tests")
struct CachingNewsServiceCategoryTests {
    let mockNewsService: MockNewsService
    let mockCacheStore: MockNewsCacheStore
    let sut: CachingNewsService

    init() {
        mockNewsService = MockNewsService()
        mockCacheStore = MockNewsCacheStore()
        sut = CachingNewsService(wrapping: mockNewsService, cacheStore: mockCacheStore, diskCacheStore: nil)
    }

    @Test("fetchTopHeadlines with category returns cached data when available")
    func fetchCategoryHeadlinesCacheHit() async throws {
        let cachedArticles = Article.mockArticles
        let cacheKey = NewsCacheKey.categoryHeadlines(language: "en", category: .technology, country: "us", page: 1)
        let entry = CacheEntry(data: cachedArticles, timestamp: Date())
        mockCacheStore.set(entry, for: cacheKey)
        mockCacheStore.getCallCount = 0

        var receivedArticles: [Article] = []
        var cancellables = Set<AnyCancellable>()

        sut.fetchTopHeadlines(category: .technology, language: "en", country: "us", page: 1)
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

    @Test("fetchTopHeadlines with category fetches from network when cache misses")
    func fetchCategoryHeadlinesCacheMiss() async throws {
        let networkArticles = Article.mockArticles
        mockNewsService.topHeadlinesResult = .success(networkArticles)

        var receivedArticles: [Article] = []
        var cancellables = Set<AnyCancellable>()

        sut.fetchTopHeadlines(category: .science, language: "en", country: "us", page: 1)
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

        let cacheKey = NewsCacheKey.categoryHeadlines(language: "en", category: .science, country: "us", page: 1)
        #expect(mockCacheStore.contains(key: cacheKey))
    }

    @Test("fetchTopHeadlines with category fetches from network when expired")
    func fetchCategoryHeadlinesExpiredCache() async throws {
        let expiredTimestamp = Date().addingTimeInterval(-NewsCacheTTL.default - 1)
        let cachedArticles = [Article.mockArticles[0]]
        let cacheKey = NewsCacheKey.categoryHeadlines(language: "en", category: .technology, country: "us", page: 1)
        let entry = CacheEntry(data: cachedArticles, timestamp: expiredTimestamp)
        mockCacheStore.set(entry, for: cacheKey)

        let networkArticles = Article.mockArticles
        mockNewsService.topHeadlinesResult = .success(networkArticles)

        mockCacheStore.getCallCount = 0
        mockCacheStore.setCallCount = 0

        var receivedArticles: [Article] = []
        var cancellables = Set<AnyCancellable>()

        sut.fetchTopHeadlines(category: .technology, language: "en", country: "us", page: 1)
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
