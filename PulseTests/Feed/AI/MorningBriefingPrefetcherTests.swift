import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("MorningBriefingPrefetcher Tests", .serialized)
@MainActor
struct MorningBriefingPrefetcherTests {
    let mockFeedService: MockFeedService
    let mockNewsService: MockNewsService
    let mockForYouService: MockForYouService
    let mockSettingsService: MockSettingsService
    let mockBriefingCacheService: MockBriefingCacheService
    let mockNotificationService: MockNotificationService

    init() {
        mockFeedService = MockFeedService()
        mockNewsService = MockNewsService()
        mockForYouService = MockForYouService()
        mockSettingsService = MockSettingsService()
        mockBriefingCacheService = MockBriefingCacheService()
        mockNotificationService = MockNotificationService()
    }

    private func makeSUT(
        isPremium: Bool? = true,
        preferences: UserPreferences
    ) -> MorningBriefingPrefetcher {
        mockSettingsService.preferences = preferences
        return MorningBriefingPrefetcher(
            feedService: mockFeedService,
            newsService: mockNewsService,
            forYouService: mockForYouService,
            settingsService: mockSettingsService,
            briefingCacheService: mockBriefingCacheService,
            notificationService: mockNotificationService,
            storeKitService: isPremium.map { MockStoreKitService(isPremium: $0) }
        )
    }

    private func enabledPreferences(hoursFromNow: Int) -> UserPreferences {
        let scheduled = Calendar.current.date(byAdding: .hour, value: hoursFromNow, to: Date()) ?? Date()
        let components = Calendar.current.dateComponents([.hour, .minute], from: scheduled)
        return UserPreferences(
            followedTopics: [], mutedSources: [], mutedKeywords: [],
            preferredLanguage: "en", notificationsEnabled: true, breakingNewsNotifications: true,
            morningBriefingEnabled: true,
            morningBriefingHour: components.hour ?? 7,
            morningBriefingMinute: components.minute ?? 0
        )
    }

    @Test("Non-premium user does not generate anything")
    func nonPremiumSkipsGeneration() async {
        let sut = makeSUT(isPremium: false, preferences: enabledPreferences(hoursFromNow: 2))

        sut.prefetchIfNeeded()
        try? await Task.sleep(nanoseconds: 300_000_000)

        #expect(mockFeedService.loadModelCallCount == 0)
        #expect(mockBriefingCacheService.storeCallCount == 0)
    }

    @Test("Non-premium user with a still-enabled preference self-heals by cancelling the notification")
    func nonPremiumDowngradeCancelsNotification() async {
        let sut = makeSUT(isPremium: false, preferences: enabledPreferences(hoursFromNow: 2))

        sut.prefetchIfNeeded()
        try? await Task.sleep(nanoseconds: 300_000_000)

        #expect(mockNotificationService.cancelMorningBriefingCallCount == 1)
    }

    @Test("Disabled preference does not generate anything")
    func disabledPreferenceSkipsGeneration() async {
        var preferences = enabledPreferences(hoursFromNow: 2)
        preferences.morningBriefingEnabled = false
        let sut = makeSUT(preferences: preferences)

        sut.prefetchIfNeeded()
        try? await Task.sleep(nanoseconds: 300_000_000)

        #expect(mockFeedService.loadModelCallCount == 0)
    }

    @Test("Past the scheduled time does not generate anything")
    func pastScheduledTimeSkipsGeneration() async {
        let sut = makeSUT(preferences: enabledPreferences(hoursFromNow: -1))

        sut.prefetchIfNeeded()
        try? await Task.sleep(nanoseconds: 300_000_000)

        #expect(mockFeedService.loadModelCallCount == 0)
    }

    @Test("Already-cached briefing does not regenerate")
    func alreadyCachedSkipsGeneration() async {
        mockBriefingCacheService.fetchResult = PregeneratedBriefing(
            digest: DailyDigest(id: "cached", summary: "s", sourceArticles: [], generatedAt: Date()),
            queueArticles: [],
            generatedAt: Date()
        )
        let sut = makeSUT(preferences: enabledPreferences(hoursFromNow: 2))

        sut.prefetchIfNeeded()
        try? await Task.sleep(nanoseconds: 300_000_000)

        #expect(mockFeedService.loadModelCallCount == 0)
    }

    @Test("Eligible state generates a digest and stores it in the cache")
    func eligibleStateGeneratesAndCaches() async {
        mockFeedService.loadDelay = 0.01
        mockFeedService.generateDelay = 0.005
        mockNewsService.topHeadlinesResult = .success([
            Article(
                id: "a1", title: "Title", description: "Desc", content: "Content",
                source: ArticleSource(id: nil, name: "Source"), url: "https://example.com/a1",
                publishedAt: Date()
            ),
        ])
        let sut = makeSUT(preferences: enabledPreferences(hoursFromNow: 2))

        sut.prefetchIfNeeded()

        let stored = await waitForCondition(timeout: 3_000_000_000) { @MainActor in
            self.mockBriefingCacheService.storeCallCount > 0
        }
        #expect(stored)
        #expect(mockFeedService.loadModelCallCount > 0)
    }

    @Test("A generation failure (e.g. the shared LLM busy gate) is swallowed silently")
    func generationFailureIsSwallowed() async {
        mockFeedService.shouldFail = true
        mockNewsService.topHeadlinesResult = .success([
            Article(
                id: "a1", title: "Title", description: "Desc", content: "Content",
                source: ArticleSource(id: nil, name: "Source"), url: "https://example.com/a1",
                publishedAt: Date()
            ),
        ])
        let sut = makeSUT(preferences: enabledPreferences(hoursFromNow: 2))

        sut.prefetchIfNeeded()
        try? await Task.sleep(nanoseconds: 500_000_000)

        #expect(mockBriefingCacheService.storeCallCount == 0)
    }

    @Test("A prefetch already in flight is not duplicated by a second kick")
    func inFlightPrefetchIsNotDuplicated() async {
        // The in-flight guard only needs the two calls to land before the
        // first `Task` has a chance to finish — since `prefetchIfNeeded()`
        // sets `prefetchTask` synchronously before any `await`, calling it
        // twice back-to-back with no suspension in between is sufficient;
        // a large artificial delay isn't needed and would just slow the test.
        mockFeedService.loadDelay = 0.01
        mockFeedService.generateDelay = 0.005
        mockNewsService.topHeadlinesResult = .success([
            Article(
                id: "a1", title: "Title", description: "Desc", content: "Content",
                source: ArticleSource(id: nil, name: "Source"), url: "https://example.com/a1",
                publishedAt: Date()
            ),
        ])
        let sut = makeSUT(preferences: enabledPreferences(hoursFromNow: 2))

        sut.prefetchIfNeeded()
        sut.prefetchIfNeeded()

        _ = await waitForCondition(timeout: 3_000_000_000) { @MainActor in
            self.mockBriefingCacheService.storeCallCount > 0
        }
        #expect(mockBriefingCacheService.storeCallCount == 1)
    }
}
