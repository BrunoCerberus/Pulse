import Combine
import Foundation
@testable import Pulse
import Testing

@Suite("CachingNewsService Top Headlines Tests")
struct CachingNewsServiceTopHeadlinesTests {
    let mockNewsService: MockNewsService
    let mockCacheStore: MockNewsCacheStore
    let sut: CachingNewsService

    init() {
        mockNewsService = MockNewsService()
        mockCacheStore = MockNewsCacheStore()
        sut = CachingNewsService(wrapping: mockNewsService, cacheStore: mockCacheStore, diskCacheStore: nil)
    }

    @Test("fetchTopHeadlines returns cached data when available and not expired")
    func fetchTopHeadlinesCacheHit() async throws {
        let cachedArticles = Article.mockArticles
        let cacheKey = NewsCacheKey.topHeadlines(country: "us", page: 1)
        let entry = CacheEntry(data: cachedArticles, timestamp: Date())
        mockCacheStore.set(entry, for: cacheKey)

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

        let cacheKey = NewsCacheKey.topHeadlines(country: "us", page: 1)
        #expect(mockCacheStore.contains(key: cacheKey))
    }

    @Test("fetchTopHeadlines fetches from network when cache is expired")
    func fetchTopHeadlinesExpiredCache() async throws {
        let expiredTimestamp = Date().addingTimeInterval(-NewsCacheTTL.default - 1)
        let cachedArticles = [Article.mockArticles[0]]
        let cacheKey = NewsCacheKey.topHeadlines(country: "us", page: 1)
        let entry = CacheEntry(data: cachedArticles, timestamp: expiredTimestamp)
        mockCacheStore.set(entry, for: cacheKey)

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

        #expect(receivedArticles == networkArticles)
        #expect(mockCacheStore.setCallCount == 1)
    }
}
