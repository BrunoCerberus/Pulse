import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("Feed Audio Briefing Tests", .serialized)
@MainActor
struct FeedBriefingTests {
    let mockFeedService: MockFeedService
    let mockNewsService: MockNewsService
    let mockForYouService: MockForYouService
    let mockPlaybackQueueService: MockPlaybackQueueService
    let serviceLocator: ServiceLocator
    let sut: FeedDomainInteractor

    init() {
        mockFeedService = MockFeedService()
        mockNewsService = MockNewsService()
        mockForYouService = MockForYouService()
        mockPlaybackQueueService = MockPlaybackQueueService()
        serviceLocator = ServiceLocator()

        serviceLocator.register(FeedService.self, instance: mockFeedService)
        serviceLocator.register(NewsService.self, instance: mockNewsService)
        serviceLocator.register(NetworkMonitorService.self, instance: MockNetworkMonitorService())
        serviceLocator.register(AnalyticsService.self, instance: MockAnalyticsService())
        serviceLocator.register(StoreKitService.self, instance: MockStoreKitService(isPremium: true))
        serviceLocator.register(ForYouService.self, instance: mockForYouService)
        serviceLocator.register(PlaybackQueueService.self, instance: mockPlaybackQueueService)

        sut = FeedDomainInteractor(serviceLocator: serviceLocator)
    }

    // MARK: - Premium Gate

    @Test("Briefing is blocked at the service boundary when StoreKit is not premium")
    func briefingBlockedWhenNotPremium() async {
        let locator = ServiceLocator()
        locator.register(FeedService.self, instance: MockFeedService())
        locator.register(NewsService.self, instance: MockNewsService())
        locator.register(StoreKitService.self, instance: MockStoreKitService(isPremium: false))
        locator.register(ForYouService.self, instance: mockForYouService)
        locator.register(PlaybackQueueService.self, instance: mockPlaybackQueueService)
        let gated = FeedDomainInteractor(serviceLocator: locator)

        gated.dispatch(action: .digestCompleted(makeDigest()))
        gated.dispatch(action: .latestArticlesLoaded([makeArticle(id: "a1")]))
        gated.dispatch(action: .startAudioBriefing)

        let played = await waitForCondition(timeout: 300_000_000) { @MainActor in
            mockPlaybackQueueService.playCallCount > 0
        }
        #expect(!played, "Premium gate should block briefing before any playback")
    }

    @Test("Briefing requires a completed digest")
    func briefingRequiresDigest() async {
        sut.dispatch(action: .latestArticlesLoaded([makeArticle(id: "a1")]))
        sut.dispatch(action: .startAudioBriefing)

        let played = await waitForCondition(timeout: 300_000_000) { @MainActor in
            mockPlaybackQueueService.playCallCount > 0
        }
        #expect(!played, "Briefing without a digest should not start playback")
    }

    // MARK: - Queue Assembly

    @Test("Queue is digest narration first, then For You articles in scored order")
    func briefingAssemblyOrder() async throws {
        let first = makeArticle(id: "a1", title: "First")
        let second = makeArticle(id: "a2", title: "Second")
        // Scored order deliberately differs from pool order to prove the
        // queue follows personalization ranking, not fetch order.
        mockForYouService.scoredArticlesResult = .success([
            ScoredArticle(article: second, score: 0.9, matchedTopics: []),
            ScoredArticle(article: first, score: 0.5, matchedTopics: []),
        ])

        await startBriefing(digest: makeDigest(id: "daily-1"), articles: [first, second])

        let items = try #require(mockPlaybackQueueService.lastPlayedItems)
        #expect(items.map(\.id) == ["digest-daily-1", "a2", "a1"])
        #expect(items[0].kind == .digest)
        #expect(mockPlaybackQueueService.lastPlayedMode == .briefing)
        #expect(mockForYouService.lastTopN == 10)
    }

    @Test("Briefing article count follows the user's configured preference")
    func briefingUsesConfiguredArticleCount() async {
        let locator = ServiceLocator()
        let settingsService = MockSettingsService()
        settingsService.preferences.morningBriefingArticleCount = 5
        locator.register(FeedService.self, instance: MockFeedService())
        locator.register(NewsService.self, instance: MockNewsService())
        locator.register(StoreKitService.self, instance: MockStoreKitService(isPremium: true))
        locator.register(ForYouService.self, instance: mockForYouService)
        locator.register(PlaybackQueueService.self, instance: mockPlaybackQueueService)
        locator.register(SettingsService.self, instance: settingsService)
        let interactor = FeedDomainInteractor(serviceLocator: locator)

        interactor.dispatch(action: .digestCompleted(makeDigest(id: "daily-1")))
        interactor.dispatch(action: .latestArticlesLoaded([makeArticle(id: "a1")]))
        interactor.dispatch(action: .startAudioBriefing)

        let played = await waitForCondition { @MainActor in
            mockPlaybackQueueService.playCallCount > 0
        }
        #expect(played)
        #expect(mockForYouService.lastTopN == 5)
    }

    @Test("Media items are filtered out of the personalization pool")
    func briefingFiltersMediaFromPool() async {
        let article = makeArticle(id: "a1")
        let video = makeArticle(id: "v1", mediaType: .video)

        await startBriefing(digest: makeDigest(), articles: [article, video])

        #expect(mockForYouService.lastPool.map(\.id) == ["a1"])
    }

    // MARK: - Digest-Only Fallback

    @Test("Empty For You results fall back to a digest-only queue")
    func briefingFallsBackToDigestOnlyWhenForYouEmpty() async throws {
        mockForYouService.scoredArticlesResult = .success([])

        await startBriefing(digest: makeDigest(id: "daily-1"), articles: [makeArticle(id: "a1")])

        let items = try #require(mockPlaybackQueueService.lastPlayedItems)
        #expect(items.map(\.id) == ["digest-daily-1"])
        #expect(mockPlaybackQueueService.lastPlayedMode == .briefing)
    }

    @Test("For You scoring errors fall back to a digest-only queue")
    func briefingFallsBackToDigestOnlyWhenForYouFails() async throws {
        mockForYouService.scoredArticlesResult = .failure(URLError(.unknown))

        await startBriefing(digest: makeDigest(id: "daily-1"), articles: [makeArticle(id: "a1")])

        let items = try #require(mockPlaybackQueueService.lastPlayedItems)
        #expect(items.map(\.id) == ["digest-daily-1"])
    }

    @Test("Missing ForYouService falls back to a digest-only queue")
    func briefingFallsBackToDigestOnlyWithoutForYouService() async throws {
        let locator = ServiceLocator()
        locator.register(FeedService.self, instance: MockFeedService())
        locator.register(NewsService.self, instance: MockNewsService())
        locator.register(StoreKitService.self, instance: MockStoreKitService(isPremium: true))
        locator.register(PlaybackQueueService.self, instance: mockPlaybackQueueService)
        let interactor = FeedDomainInteractor(serviceLocator: locator)

        interactor.dispatch(action: .digestCompleted(makeDigest(id: "daily-1")))
        interactor.dispatch(action: .latestArticlesLoaded([makeArticle(id: "a1")]))
        interactor.dispatch(action: .startAudioBriefing)

        let played = await waitForCondition { @MainActor in
            mockPlaybackQueueService.playCallCount > 0
        }
        #expect(played)
        let items = try #require(mockPlaybackQueueService.lastPlayedItems)
        #expect(items.map(\.id) == ["digest-daily-1"])
    }

    // MARK: - Narration Text

    @Test("Digest narration strips markdown the TTS engine would read literally")
    func briefingDigestSpeechTextStripsMarkdown() async throws {
        let digest = makeDigest(
            id: "daily-1",
            summary: """
            # Today's Highlights
            **Technology** advances continue.
            - First story about chips
            * Second story about software
            """,
        )
        mockForYouService.scoredArticlesResult = .success([])

        await startBriefing(digest: digest, articles: [])

        let items = try #require(mockPlaybackQueueService.lastPlayedItems)
        let speech = try #require(items.first?.speechText)
        #expect(speech.hasPrefix(AppLocalization.localized("briefing.intro")))
        #expect(!speech.contains("**"))
        #expect(!speech.contains("#"))
        #expect(!speech.contains("\n- "))
        #expect(!speech.contains("\n* "))
        #expect(speech.contains("Technology"))
        #expect(speech.contains("First story about chips"))
        #expect(speech.contains("Second story about software"))
    }

    // MARK: - Helpers

    /// Seeds a completed digest + article pool, dispatches the briefing
    /// action, and waits for the async assembly task to hand the queue to
    /// the playback service.
    private func startBriefing(digest: DailyDigest, articles: [Article]) async {
        sut.dispatch(action: .digestCompleted(digest))
        sut.dispatch(action: .latestArticlesLoaded(articles))
        sut.dispatch(action: .startAudioBriefing)

        let played = await waitForCondition { @MainActor in
            mockPlaybackQueueService.playCallCount > 0
        }
        #expect(played, "Briefing should reach the playback queue service")
    }

    private func makeDigest(
        id: String = "digest-id",
        summary: String = "**World** news summary.",
    ) -> DailyDigest {
        DailyDigest(
            id: id,
            summary: summary,
            sourceArticles: [],
            generatedAt: Date(),
        )
    }

    private func makeArticle(
        id: String,
        title: String = "Title",
        mediaType: MediaType? = nil,
    ) -> Article {
        Article(
            id: id,
            title: title,
            description: "Description",
            content: "Content",
            source: ArticleSource(id: nil, name: "Source"),
            url: "https://example.com/\(id)",
            publishedAt: Date(),
            mediaType: mediaType,
            mediaURL: mediaType == nil ? nil : "https://example.com/\(id).mp4",
        )
    }
}
