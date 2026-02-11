import Combine
import Foundation
@testable import Pulse
import Testing

@Suite("CachingNewsService Article Tests")
struct CachingNewsServiceArticleTests {
    let mockNewsService: MockNewsService
    let mockCacheStore: MockNewsCacheStore
    let sut: CachingNewsService

    init() {
        mockNewsService = MockNewsService()
        mockCacheStore = MockNewsCacheStore()
        sut = CachingNewsService(wrapping: mockNewsService, cacheStore: mockCacheStore)
    }

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

        #expect(receivedArticle == networkArticle)
        #expect(mockCacheStore.setCallCount == 1)
    }
}
