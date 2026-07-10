import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("SmartBriefingDomainInteractor Tests", .serialized)
@MainActor
struct SmartBriefingDomainInteractorTests {
    let mockNewsService: MockNewsService
    let mockForYouService: MockForYouService
    let mockPlaybackQueueService: MockPlaybackQueueService
    let mockCacheService: MockSmartBriefingCacheService
    let mockSettingsService: MockSettingsService
    let mockStoreKitService: MockStoreKitService
    let mockAnalyticsService: MockAnalyticsService
    let serviceLocator: ServiceLocator
    let sut: SmartBriefingDomainInteractor

    init() {
        mockNewsService = MockNewsService()
        mockForYouService = MockForYouService()
        mockPlaybackQueueService = MockPlaybackQueueService()
        mockCacheService = MockSmartBriefingCacheService()
        mockSettingsService = MockSettingsService()
        mockStoreKitService = MockStoreKitService(isPremium: true)
        mockAnalyticsService = MockAnalyticsService()
        serviceLocator = ServiceLocator()

        serviceLocator.register(NewsService.self, instance: mockNewsService)
        serviceLocator.register(ForYouService.self, instance: mockForYouService)
        serviceLocator.register(PlaybackQueueService.self, instance: mockPlaybackQueueService)
        serviceLocator.register(SmartBriefingCacheService.self, instance: mockCacheService)
        serviceLocator.register(SettingsService.self, instance: mockSettingsService)
        serviceLocator.register(StoreKitService.self, instance: mockStoreKitService)
        serviceLocator.register(AnalyticsService.self, instance: mockAnalyticsService)

        sut = SmartBriefingDomainInteractor(serviceLocator: serviceLocator)
    }

    @Test("Non-premium users are blocked at the service boundary")
    func nonPremiumBlocked() async {
        let locator = ServiceLocator()
        locator.register(NewsService.self, instance: MockNewsService())
        locator.register(ForYouService.self, instance: MockForYouService())
        locator.register(PlaybackQueueService.self, instance: mockPlaybackQueueService)
        locator.register(StoreKitService.self, instance: MockStoreKitService(isPremium: false))
        let gated = SmartBriefingDomainInteractor(serviceLocator: locator)

        gated.dispatch(action: .startBriefing(scope: .unreadSinceLastBriefing))

        try? await Task.sleep(nanoseconds: 100_000_000)
        #expect(mockPlaybackQueueService.playCallCount == 0)
    }

    @Test("Premium user with articles produces a briefing-mode queue and persists served IDs")
    func premiumBuildsQueue() async {
        mockNewsService.topHeadlinesResult = .success(Article.mockArticles)
        mockForYouService.scoredArticlesResult = .success(
            Article.mockArticles.map { ScoredArticle(article: $0, score: 1.0, matchedTopics: []) }
        )

        sut.dispatch(action: .startBriefing(scope: .unreadSinceLastBriefing))

        let success = await waitForCondition(timeout: 2_000_000_000) { @MainActor [mockPlaybackQueueService] in
            mockPlaybackQueueService.playCallCount > 0
        }

        #expect(success, "Should have played a queue")
        #expect(mockPlaybackQueueService.lastPlayedMode == .briefing)
        #expect(mockPlaybackQueueService.lastPlayedItems?.isEmpty == false)
        #expect(mockCacheService.storeCallCount == 1)
    }

    @Test("Empty 'since last briefing' scope widens to allUnread")
    func widensToAllUnreadWhenScopedResultIsEmpty() async {
        mockNewsService.topHeadlinesResult = .success(Article.mockArticles)
        // `Article.mockArticles` are all dated in the past relative to `.now`,
        // so a cutoff of `.now` filters the scoped pool down to empty —
        // forcing the widen-to-`.allUnread` fallback to run.
        mockCacheService.fetchResult = SmartBriefingServedRecord(servedAt: .now, servedArticleIDs: [])
        // Configuring an empty result means the *first* (scoped) call also
        // resolves empty regardless of what pool it's given, so the only way
        // `lastPool` ends up non-empty is if the widening fallback actually
        // ran its second call with the un-cutoff pool.
        mockForYouService.scoredArticlesResult = .success([])

        sut.dispatch(action: .startBriefing(scope: .unreadSinceLastBriefing))

        let resolved = await waitForCondition(timeout: 2_000_000_000) { @MainActor in
            sut.currentState.buildState == .empty
        }

        #expect(resolved)
        // The widened (`.allUnread`) call ignores the cutoff, so its pool
        // is non-empty — proving the second (widening) call actually ran,
        // since the first (scoped) call's pool would have been filtered to
        // empty by the `.now` cutoff.
        #expect(!mockForYouService.lastPool.isEmpty)
    }

    @Test("Repeat run excludes previously served article IDs")
    func repeatRunExcludesServedIDs() async {
        mockNewsService.topHeadlinesResult = .success(Article.mockArticles)
        let previouslyServedID = Article.mockArticles[0].id
        mockCacheService.fetchResult = SmartBriefingServedRecord(
            servedAt: .now.addingTimeInterval(-3600),
            servedArticleIDs: [previouslyServedID]
        )
        mockForYouService.scoredArticlesResult = .success(
            Article.mockArticles.map { ScoredArticle(article: $0, score: 1.0, matchedTopics: []) }
        )

        sut.dispatch(action: .startBriefing(scope: .unreadSinceLastBriefing))

        let success = await waitForCondition(timeout: 2_000_000_000) { @MainActor [mockPlaybackQueueService] in
            mockPlaybackQueueService.playCallCount > 0
        }
        #expect(success)

        // The pool ForYouService was scored from must not contain the
        // previously served article.
        #expect(!mockForYouService.lastPool.contains { $0.id == previouslyServedID })
    }

    @Test("Missing ForYouService resolves to empty state without crashing")
    func missingForYouServiceDegradesGracefully() async {
        let locator = ServiceLocator()
        locator.register(NewsService.self, instance: mockNewsService)
        locator.register(PlaybackQueueService.self, instance: mockPlaybackQueueService)
        locator.register(StoreKitService.self, instance: MockStoreKitService(isPremium: true))
        mockNewsService.topHeadlinesResult = .success(Article.mockArticles)
        let degraded = SmartBriefingDomainInteractor(serviceLocator: locator)

        degraded.dispatch(action: .startBriefing(scope: .unreadSinceLastBriefing))

        let resolved = await waitForCondition(timeout: 2_000_000_000) { @MainActor in
            degraded.currentState.buildState == .empty
        }

        #expect(resolved)
        #expect(mockPlaybackQueueService.playCallCount == 0)
    }
}
