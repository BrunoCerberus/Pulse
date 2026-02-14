import Combine
import Foundation
@testable import Pulse
import Testing

@Suite("CachingNewsService Breaking News Tests")
struct CachingNewsServiceBreakingNewsTests {
    let mockNewsService: MockNewsService
    let mockCacheStore: MockNewsCacheStore
    let sut: CachingNewsService

    init() {
        mockNewsService = MockNewsService()
        mockCacheStore = MockNewsCacheStore()
        sut = CachingNewsService(wrapping: mockNewsService, cacheStore: mockCacheStore, diskCacheStore: nil)
    }

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
}
