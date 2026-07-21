import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("Feed Morning Briefing Tests", .serialized)
@MainActor
struct FeedMorningBriefingTests {
    let mockFeedService: MockFeedService
    let mockNewsService: MockNewsService
    let mockForYouService: MockForYouService
    let mockPlaybackQueueService: MockPlaybackQueueService
    let mockBriefingCacheService: MockBriefingCacheService
    let serviceLocator: ServiceLocator
    let sut: FeedDomainInteractor

    init() {
        mockFeedService = MockFeedService()
        mockNewsService = MockNewsService()
        mockForYouService = MockForYouService()
        mockPlaybackQueueService = MockPlaybackQueueService()
        mockBriefingCacheService = MockBriefingCacheService()
        serviceLocator = ServiceLocator()

        serviceLocator.register(FeedService.self, instance: mockFeedService)
        serviceLocator.register(NewsService.self, instance: mockNewsService)
        serviceLocator.register(NetworkMonitorService.self, instance: MockNetworkMonitorService())
        serviceLocator.register(AnalyticsService.self, instance: MockAnalyticsService())
        serviceLocator.register(StoreKitService.self, instance: MockStoreKitService(isPremium: true))
        serviceLocator.register(ForYouService.self, instance: mockForYouService)
        serviceLocator.register(PlaybackQueueService.self, instance: mockPlaybackQueueService)
        serviceLocator.register(BriefingCacheService.self, instance: mockBriefingCacheService)

        sut = FeedDomainInteractor(serviceLocator: serviceLocator)
    }

    @Test("Morning Briefing is blocked at the service boundary when StoreKit is not premium")
    func morningBriefingBlockedWhenNotPremium() async {
        let locator = ServiceLocator()
        locator.register(FeedService.self, instance: MockFeedService())
        locator.register(NewsService.self, instance: MockNewsService())
        locator.register(StoreKitService.self, instance: MockStoreKitService(isPremium: false))
        locator.register(PlaybackQueueService.self, instance: mockPlaybackQueueService)
        locator.register(BriefingCacheService.self, instance: mockBriefingCacheService)
        let gated = FeedDomainInteractor(serviceLocator: locator)

        gated.dispatch(action: .startMorningBriefing)

        let played = await waitForCondition(timeout: 300_000_000) { @MainActor in
            mockPlaybackQueueService.playCallCount > 0
        }
        #expect(!played, "Premium gate should block the Morning Briefing before any playback")
    }

    @Test("A fresh pre-generated cache plays immediately without generating a digest")
    func morningBriefingPlaysFromCacheWithoutGenerating() async throws {
        let cachedDigest = makeDigest(id: "cached-1")
        let cachedArticle = makeArticle(id: "cached-a1")
        mockBriefingCacheService.fetchResult = PregeneratedBriefing(
            digest: cachedDigest,
            queueArticles: [cachedArticle],
            generatedAt: Date(),
        )

        sut.dispatch(action: .startMorningBriefing)

        let played = await waitForCondition { @MainActor in
            mockPlaybackQueueService.playCallCount > 0
        }
        #expect(played)
        #expect(mockFeedService.loadModelCallCount == 0, "Cached path must not trigger LLM generation")

        let items = try #require(mockPlaybackQueueService.lastPlayedItems)
        #expect(items.first?.id == "digest-cached-1")
    }

    @Test("An already-loaded digest this session plays immediately, bypassing the cache")
    func morningBriefingPlaysFromCurrentSessionDigest() async throws {
        sut.dispatch(action: .digestCompleted(makeDigest(id: "session-1")))
        sut.dispatch(action: .latestArticlesLoaded([makeArticle(id: "a1")]))

        sut.dispatch(action: .startMorningBriefing)

        let played = await waitForCondition { @MainActor in
            mockPlaybackQueueService.playCallCount > 0
        }
        #expect(played)
        #expect(mockBriefingCacheService.storedBriefing == nil, "No cache write should occur on this path")

        let items = try #require(mockPlaybackQueueService.lastPlayedItems)
        #expect(items.first?.id == "digest-session-1")
    }

    @Test("No cache and no session digest falls back to on-demand generation, then auto-plays")
    func morningBriefingFallsBackToOnDemandGeneration() async {
        mockFeedService.loadDelay = 0.01
        mockFeedService.generateDelay = 0.005
        mockNewsService.topHeadlinesResult = .success([makeArticle(id: "fresh-1")])

        sut.dispatch(action: .startMorningBriefing)

        let played = await waitForCondition(timeout: 3_000_000_000) { @MainActor in
            mockPlaybackQueueService.playCallCount > 0
        }
        #expect(played, "Fallback generation should complete and auto-play")
        #expect(mockFeedService.loadModelCallCount > 0, "Fallback path must go through LLM generation")
    }

    // MARK: - Helpers

    private func makeDigest(
        id: String = "digest-id",
        summary: String = "World news summary.",
    ) -> DailyDigest {
        DailyDigest(
            id: id,
            summary: summary,
            sourceArticles: [],
            generatedAt: Date(),
        )
    }

    private func makeArticle(id: String, title: String = "Title") -> Article {
        Article(
            id: id,
            title: title,
            description: "Description",
            content: "Content",
            source: ArticleSource(id: nil, name: "Source"),
            url: "https://example.com/\(id)",
            publishedAt: Date(),
        )
    }
}
