import Combine
import Foundation
@testable import Pulse
import Testing

@Suite("CachingNewsService Integration Tests")
struct CachingNewsServiceIntegrationTests {
    let sut: CachingNewsService
    let mockWrapped: MockNewsService
    let mockL1: MockNewsCacheStore
    let diskL2: DiskNewsCacheStore
    let mockNetwork: MockNetworkMonitorService
    let testDirectory: URL

    init() {
        mockWrapped = MockNewsService()
        mockL1 = MockNewsCacheStore()
        testDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("CachingIntegration_\(UUID().uuidString)", isDirectory: true)
        diskL2 = DiskNewsCacheStore(directory: testDirectory)
        mockNetwork = MockNetworkMonitorService(isConnected: true)
        sut = CachingNewsService(
            wrapping: mockWrapped,
            cacheStore: mockL1,
            diskCacheStore: diskL2,
            networkMonitor: mockNetwork,
            networkResilienceEnabled: false
        )
    }

    private func cleanup() {
        try? FileManager.default.removeItem(at: testDirectory)
    }

    // MARK: - L1 Cache Hit

    @Test("L1 cache hit returns immediately without calling wrapped service")
    func l1CacheHitSkipsNetwork() async throws {
        defer { cleanup() }

        let key = NewsCacheKey.topHeadlines(language: "en", country: "us", page: 1)
        let articles = Article.mockArticles
        let entry = CacheEntry(data: articles, timestamp: Date())
        mockL1.set(entry, for: key)

        let result = try await awaitPublisher(
            sut.fetchTopHeadlines(language: "en", country: "us", page: 1)
        )

        #expect(result.count == articles.count)
        #expect(mockWrapped.fetchedTopHeadlinesLanguages.isEmpty)
    }

    // MARK: - L2 Cache Hit Promotes to L1

    @Test("L2 cache hit promotes to L1 and skips network")
    func l2CacheHitPromotesToL1() async throws {
        defer { cleanup() }

        let key = NewsCacheKey.topHeadlines(language: "en", country: "us", page: 1)
        let articles = Article.mockArticles
        let entry = CacheEntry(data: articles, timestamp: Date())
        diskL2.set(entry, for: key)

        let initialSetCount = mockL1.setCallCount

        let result = try await awaitPublisher(
            sut.fetchTopHeadlines(language: "en", country: "us", page: 1)
        )

        #expect(result.count == articles.count)
        #expect(mockWrapped.fetchedTopHeadlinesLanguages.isEmpty)
        #expect(mockL1.setCallCount > initialSetCount, "L1 should be populated from L2")
    }

    // MARK: - Cache Miss Populates Both Caches

    @Test("Cache miss fetches from network and populates both L1 and L2")
    func cacheMissPopulatesBothCaches() async throws {
        defer { cleanup() }

        let key = NewsCacheKey.topHeadlines(language: "en", country: "us", page: 1)
        let initialL1SetCount = mockL1.setCallCount

        let result = try await awaitPublisher(
            sut.fetchTopHeadlines(language: "en", country: "us", page: 1)
        )

        #expect(result.count == Article.mockArticles.count)
        #expect(mockWrapped.fetchedTopHeadlinesLanguages == ["en"])
        #expect(mockL1.setCallCount > initialL1SetCount, "L1 should be populated")

        let diskEntry: CacheEntry<[Article]>? = diskL2.get(for: key)
        #expect(diskEntry != nil, "L2 should be populated")
        #expect(diskEntry?.data.count == Article.mockArticles.count)
    }

    // MARK: - Offline Scenarios

    @Test("Offline with stale L1 returns stale data")
    func offlineWithStaleL1ReturnsStaleData() async throws {
        defer { cleanup() }

        let key = NewsCacheKey.topHeadlines(language: "en", country: "us", page: 1)
        let staleTimestamp = Date().addingTimeInterval(-700) // Past 10-min TTL
        let entry = CacheEntry(data: Article.mockArticles, timestamp: staleTimestamp)
        mockL1.set(entry, for: key)

        mockNetwork.simulateOffline()

        let result = try await awaitPublisher(
            sut.fetchTopHeadlines(language: "en", country: "us", page: 1)
        )

        #expect(result.count == Article.mockArticles.count)
        #expect(mockWrapped.fetchedTopHeadlinesLanguages.isEmpty)
    }

    @Test("Offline with stale L2 only returns stale L2 data")
    func offlineWithStaleL2ReturnsStaleData() async throws {
        defer { cleanup() }

        let key = NewsCacheKey.breakingNews(language: "en", country: "us")
        let staleTimestamp = Date().addingTimeInterval(-90000) // Past 24h TTL
        let articles = Array(Article.mockArticles.prefix(2))
        let entry = CacheEntry(data: articles, timestamp: staleTimestamp)
        diskL2.set(entry, for: key)

        mockNetwork.simulateOffline()

        let result = try await awaitPublisher(
            sut.fetchBreakingNews(language: "en", country: "us")
        )

        #expect(result.count == 2)
    }

    @Test("Offline with no cache returns offlineNoCache error")
    func offlineNoCacheReturnsError() async {
        defer { cleanup() }

        mockNetwork.simulateOffline()

        do {
            _ = try await awaitPublisher(
                sut.fetchTopHeadlines(language: "en", country: "us", page: 1)
            )
            Issue.record("Expected offlineNoCache error")
        } catch {
            #expect(error is PulseError)
            #expect((error as? PulseError) == .offlineNoCache)
        }
    }

    // MARK: - Network Failure Fallback

    @Test("Network failure falls back to stale L2 data")
    func networkFailureFallsBackToStaleL2() async throws {
        defer { cleanup() }

        let key = NewsCacheKey.topHeadlines(language: "en", country: "us", page: 1)
        let staleTimestamp = Date().addingTimeInterval(-90000)
        let articles = Array(Article.mockArticles.prefix(3))
        diskL2.set(CacheEntry(data: articles, timestamp: staleTimestamp), for: key)

        mockWrapped.topHeadlinesResult = .failure(URLError(.notConnectedToInternet))

        let result = try await awaitPublisher(
            sut.fetchTopHeadlines(language: "en", country: "us", page: 1)
        )

        #expect(result.count == 3)
    }

    @Test("Network failure with no stale cache propagates error")
    func networkFailureNoStalePropagatesError() async {
        defer { cleanup() }

        mockWrapped.topHeadlinesResult = .failure(URLError(.timedOut))

        do {
            _ = try await awaitPublisher(
                sut.fetchTopHeadlines(language: "en", country: "us", page: 1)
            )
            Issue.record("Expected error to propagate")
        } catch {
            #expect(error is URLError)
        }
    }

    // MARK: - Cache Invalidation

    @Test("invalidateCache clears L1 only, preserves L2")
    func invalidateCacheClearsL1Only() {
        defer { cleanup() }

        let key = NewsCacheKey.topHeadlines(language: "en", country: "us", page: 1)
        let entry = CacheEntry(data: Article.mockArticles, timestamp: Date())
        mockL1.set(entry, for: key)
        diskL2.set(entry, for: key)

        sut.invalidateCache()

        #expect(mockL1.removeAllCallCount == 1)
        let diskEntry: CacheEntry<[Article]>? = diskL2.get(for: key)
        #expect(diskEntry != nil, "L2 should be preserved")
    }

    @Test("invalidateAllCaches clears both L1 and L2")
    func invalidateAllCachesClearsBoth() {
        defer { cleanup() }

        let key = NewsCacheKey.topHeadlines(language: "en", country: "us", page: 1)
        let entry = CacheEntry(data: Article.mockArticles, timestamp: Date())
        mockL1.set(entry, for: key)
        diskL2.set(entry, for: key)

        sut.invalidateAllCaches()

        #expect(mockL1.removeAllCallCount == 1)
        let diskEntry: CacheEntry<[Article]>? = diskL2.get(for: key)
        #expect(diskEntry == nil, "L2 should be cleared")
    }

    // MARK: - Single Article Caching

    @Test("fetchArticle caches single article through both tiers")
    func fetchArticleCachesBothTiers() async throws {
        defer { cleanup() }

        let article = Article.mockArticles[0]
        let key = NewsCacheKey.article(id: article.id)

        let result = try await awaitPublisher(
            sut.fetchArticle(id: article.id)
        )

        #expect(result.id == article.id)

        let diskEntry: CacheEntry<Article>? = diskL2.get(for: key)
        #expect(diskEntry != nil, "Single article should be in L2")
        #expect(diskEntry?.data.id == article.id)
    }

    // MARK: - Category Headlines Use Distinct Keys

    @Test("Category headlines use distinct cache keys")
    func categoryHeadlinesUseDistinctKeys() async throws {
        defer { cleanup() }

        _ = try await awaitPublisher(
            sut.fetchTopHeadlines(category: .technology, language: "en", country: "us", page: 1)
        )
        _ = try await awaitPublisher(
            sut.fetchTopHeadlines(category: .sports, language: "en", country: "us", page: 1)
        )

        let techKey = NewsCacheKey.categoryHeadlines(language: "en", category: .technology, country: "us", page: 1)
        let sportsKey = NewsCacheKey.categoryHeadlines(language: "en", category: .sports, country: "us", page: 1)

        let techEntry: CacheEntry<[Article]>? = diskL2.get(for: techKey)
        let sportsEntry: CacheEntry<[Article]>? = diskL2.get(for: sportsKey)

        #expect(techEntry != nil, "Technology cache should exist")
        #expect(sportsEntry != nil, "Sports cache should exist")
    }
}
