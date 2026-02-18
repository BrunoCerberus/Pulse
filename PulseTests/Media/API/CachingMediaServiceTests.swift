import Combine
import Foundation
@testable import Pulse
import Testing

@Suite("CachingMediaService Tests")
struct CachingMediaServiceTests {
    let mockMediaService: MockMediaService
    let mockCacheStore: MockNewsCacheStore
    let sut: CachingMediaService

    init() {
        mockMediaService = MockMediaService()
        mockMediaService.simulatedDelay = 0
        mockCacheStore = MockNewsCacheStore()
        sut = CachingMediaService(
            wrapping: mockMediaService,
            cacheStore: mockCacheStore,
            diskCacheStore: nil
        )
    }

    // MARK: - fetchMedia Tests

    @Test("fetchMedia returns cached data when available and not expired")
    func fetchMediaCacheHit() async throws {
        let cachedArticles = MockMediaService.sampleMedia
        let cacheKey = NewsCacheKey.media(language: "en", type: nil, page: 1)
        let entry = CacheEntry(data: cachedArticles, timestamp: Date())
        mockCacheStore.set(entry, for: cacheKey)

        mockCacheStore.getCallCount = 0
        mockCacheStore.setCallCount = 0

        var receivedArticles: [Article] = []
        var cancellables = Set<AnyCancellable>()

        sut.fetchMedia(type: nil, language: "en", page: 1)
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

    @Test("fetchMedia fetches from network when cache is empty")
    func fetchMediaCacheMiss() async throws {
        var receivedArticles: [Article] = []
        var cancellables = Set<AnyCancellable>()

        sut.fetchMedia(type: nil, language: "en", page: 1)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { articles in
                    receivedArticles = articles
                }
            )
            .store(in: &cancellables)

        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(!receivedArticles.isEmpty)
        #expect(mockCacheStore.getCallCount == 1)
        #expect(mockCacheStore.setCallCount == 1)

        let cacheKey = NewsCacheKey.media(language: "en", type: nil, page: 1)
        #expect(mockCacheStore.contains(key: cacheKey))
    }

    @Test("fetchMedia fetches from network when cache is expired")
    func fetchMediaExpiredCache() async throws {
        let expiredTimestamp = Date().addingTimeInterval(-NewsCacheTTL.default - 1)
        let cachedArticles = [MockMediaService.sampleMedia[0]]
        let cacheKey = NewsCacheKey.media(language: "en", type: nil, page: 1)
        let entry = CacheEntry(data: cachedArticles, timestamp: expiredTimestamp)
        mockCacheStore.set(entry, for: cacheKey)

        mockCacheStore.getCallCount = 0
        mockCacheStore.setCallCount = 0

        var receivedArticles: [Article] = []
        var cancellables = Set<AnyCancellable>()

        sut.fetchMedia(type: nil, language: "en", page: 1)
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

    @Test("fetchMedia uses correct cache key for video type")
    func fetchMediaVideoType() async throws {
        let cachedArticles = MockMediaService.sampleMedia.filter { $0.mediaType == .video }
        let cacheKey = NewsCacheKey.media(language: "en", type: "video", page: 1)
        let entry = CacheEntry(data: cachedArticles, timestamp: Date())
        mockCacheStore.set(entry, for: cacheKey)

        mockCacheStore.getCallCount = 0

        var receivedArticles: [Article] = []
        var cancellables = Set<AnyCancellable>()

        sut.fetchMedia(type: .video, language: "en", page: 1)
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

    // MARK: - fetchFeaturedMedia Tests

    @Test("fetchFeaturedMedia returns cached data when available")
    func fetchFeaturedMediaCacheHit() async throws {
        let cachedArticles = Array(MockMediaService.sampleMedia.prefix(3))
        let cacheKey = NewsCacheKey.featuredMedia(language: "en", type: nil)
        let entry = CacheEntry(data: cachedArticles, timestamp: Date())
        mockCacheStore.set(entry, for: cacheKey)

        mockCacheStore.getCallCount = 0
        mockCacheStore.setCallCount = 0

        var receivedArticles: [Article] = []
        var cancellables = Set<AnyCancellable>()

        sut.fetchFeaturedMedia(type: nil, language: "en")
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

    @Test("fetchFeaturedMedia fetches from network when cache is empty")
    func fetchFeaturedMediaCacheMiss() async throws {
        var receivedArticles: [Article] = []
        var cancellables = Set<AnyCancellable>()

        sut.fetchFeaturedMedia(type: nil, language: "en")
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

    // MARK: - Cache Invalidation Tests

    @Test("invalidateCache clears L1 memory cache")
    func invalidateCacheClearsL1() {
        let cacheKey = NewsCacheKey.media(language: "en", type: nil, page: 1)
        let entry = CacheEntry(data: MockMediaService.sampleMedia, timestamp: Date())
        mockCacheStore.set(entry, for: cacheKey)

        sut.invalidateCache()

        #expect(mockCacheStore.removeAllCallCount == 1)
    }

    @Test("invalidateCache for specific keys only removes those keys")
    func invalidateCacheForKeys() {
        let key1 = NewsCacheKey.media(language: "en", type: nil, page: 1)
        let key2 = NewsCacheKey.media(language: "en", type: nil, page: 2)
        let entry = CacheEntry(data: MockMediaService.sampleMedia, timestamp: Date())
        mockCacheStore.set(entry, for: key1)
        mockCacheStore.set(entry, for: key2)

        mockCacheStore.removeCallCount = 0

        sut.invalidateCache(for: [key1])

        #expect(mockCacheStore.removeCallCount == 1)
        #expect(!mockCacheStore.contains(key: key1))
        #expect(mockCacheStore.contains(key: key2))
    }

    // MARK: - Offline Tests

    @Test("Offline with cached data returns stale cache")
    func offlineWithCachedData() async throws {
        let mockNetworkMonitor = MockNetworkMonitorService(isConnected: false)
        let offlineSut = CachingMediaService(
            wrapping: mockMediaService,
            cacheStore: mockCacheStore,
            diskCacheStore: nil,
            networkMonitor: mockNetworkMonitor
        )

        // Store expired data in L1
        let cachedArticles = MockMediaService.sampleMedia
        let cacheKey = NewsCacheKey.media(language: "en", type: nil, page: 1)
        let expiredTimestamp = Date().addingTimeInterval(-NewsCacheTTL.default - 1)
        let expiredEntry = CacheEntry(data: cachedArticles, timestamp: expiredTimestamp)
        mockCacheStore.set(expiredEntry, for: cacheKey)
        mockCacheStore.getCallCount = 0

        var receivedArticles: [Article] = []
        var cancellables = Set<AnyCancellable>()

        offlineSut.fetchMedia(type: nil, language: "en", page: 1)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { articles in
                    receivedArticles = articles
                }
            )
            .store(in: &cancellables)

        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(receivedArticles == cachedArticles)
    }

    @Test("Offline with no cache returns offlineNoCache error")
    func offlineNoCacheReturnsError() async throws {
        let mockNetworkMonitor = MockNetworkMonitorService(isConnected: false)
        let offlineSut = CachingMediaService(
            wrapping: mockMediaService,
            cacheStore: mockCacheStore,
            diskCacheStore: nil,
            networkMonitor: mockNetworkMonitor
        )

        var receivedError: Error?
        var cancellables = Set<AnyCancellable>()

        offlineSut.fetchMedia(type: nil, language: "en", page: 1)
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        receivedError = error
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)

        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(receivedError != nil)
        #expect(receivedError?.isOfflineError == true)
    }
}
