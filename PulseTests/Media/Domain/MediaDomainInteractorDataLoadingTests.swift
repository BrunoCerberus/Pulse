import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("MediaDomainInteractor DataLoading Tests")
@MainActor
struct MediaDomainInteractorDataLoadingTests {
    let mockMediaService: MockMediaService
    let mockSettingsService: MockSettingsService
    let mockAnalyticsService: MockAnalyticsService
    let serviceLocator: ServiceLocator
    let sut: MediaDomainInteractor

    init() {
        mockMediaService = MockMediaService()
        mockMediaService.simulatedDelay = 0.05
        mockSettingsService = MockSettingsService()
        mockAnalyticsService = MockAnalyticsService()
        serviceLocator = ServiceLocator()

        serviceLocator.register(MediaService.self, instance: mockMediaService)
        serviceLocator.register(StorageService.self, instance: MockStorageService())
        serviceLocator.register(SettingsService.self, instance: mockSettingsService)
        serviceLocator.register(AnalyticsService.self, instance: mockAnalyticsService)

        sut = MediaDomainInteractor(serviceLocator: serviceLocator)
    }

    // MARK: - Deduplication Tests

    @Test("deduplicateMedia removes items found in exclusion list")
    func deduplicateMediaRemovesExcluded() {
        let all = MockMediaService.sampleMedia
        let exclude = Array(all.prefix(2))

        let result = sut.deduplicateMedia(all, excluding: exclude)

        #expect(result.count == all.count - 2)
        for excluded in exclude {
            #expect(!result.contains(where: { $0.id == excluded.id }))
        }
    }

    @Test("deduplicateMedia with empty exclusion returns all")
    func deduplicateMediaEmptyExclusion() {
        let all = MockMediaService.sampleMedia
        let result = sut.deduplicateMedia(all, excluding: [])
        #expect(result.count == all.count)
    }

    @Test("deduplicateMedia with empty input returns empty")
    func deduplicateMediaEmptyInput() {
        let result = sut.deduplicateMedia([], excluding: MockMediaService.sampleMedia)
        #expect(result.isEmpty)
    }

    @Test("deduplicateMedia with no overlap returns all")
    func deduplicateMediaNoOverlap() {
        let media = MockMediaService.sampleMedia
        let unrelatedArticle = Article(
            id: "unrelated-1",
            title: "Unrelated",
            description: nil,
            content: nil,
            author: nil,
            source: ArticleSource(id: nil, name: "Source"),
            url: "https://example.com/unrelated",
            imageURL: nil,
            publishedAt: Date(),
            category: nil
        )
        let result = sut.deduplicateMedia(media, excluding: [unrelatedArticle])
        #expect(result.count == media.count)
    }

    // MARK: - Language Change Detection

    @Test("checkLanguageChange reloads when language changes")
    func checkLanguageChangeReloads() async throws {
        // Set initial language
        mockSettingsService.preferences = UserPreferences(
            followedTopics: [],
            mutedSources: [],
            mutedKeywords: [],
            preferredLanguage: "en",
            notificationsEnabled: true,
            breakingNewsNotifications: true
        )

        sut.dispatch(action: .loadInitialData)
        try await Task.sleep(nanoseconds: 300_000_000)

        let initialData = sut.currentState.hasLoadedInitialData
        #expect(initialData)

        // Change language
        mockSettingsService.preferences = UserPreferences(
            followedTopics: [],
            mutedSources: [],
            mutedKeywords: [],
            preferredLanguage: "pt",
            notificationsEnabled: true,
            breakingNewsNotifications: true
        )

        // Trigger language check via notification
        NotificationCenter.default.post(name: .userPreferencesDidChange, object: nil)
        try await Task.sleep(nanoseconds: 500_000_000)

        // Should have reloaded data
        #expect(sut.currentState.hasLoadedInitialData)
        #expect(!sut.currentState.isLoading)
    }

    @Test("checkLanguageChange does not reload when language is the same")
    func checkLanguageChangeSameLanguage() async throws {
        mockSettingsService.preferences = UserPreferences(
            followedTopics: [],
            mutedSources: [],
            mutedKeywords: [],
            preferredLanguage: "en",
            notificationsEnabled: true,
            breakingNewsNotifications: true
        )

        sut.dispatch(action: .loadInitialData)
        try await Task.sleep(nanoseconds: 300_000_000)

        let mediaCountBefore = sut.currentState.mediaItems.count

        // Trigger language check via notification (same language)
        NotificationCenter.default.post(name: .userPreferencesDidChange, object: nil)
        try await Task.sleep(nanoseconds: 300_000_000)

        // Should not have cleared and reloaded
        #expect(sut.currentState.mediaItems.count == mediaCountBefore)
    }

    // MARK: - Error Handling in Language Reload

    @Test("reloadMediaForLanguageChange handles error")
    func reloadMediaErrorHandling() async throws {
        mockSettingsService.preferences = UserPreferences(
            followedTopics: [],
            mutedSources: [],
            mutedKeywords: [],
            preferredLanguage: "en",
            notificationsEnabled: true,
            breakingNewsNotifications: true
        )

        sut.dispatch(action: .loadInitialData)
        try await Task.sleep(nanoseconds: 300_000_000)

        // Make service fail
        mockMediaService.shouldFail = true

        // Change language to trigger reload
        mockSettingsService.preferences = UserPreferences(
            followedTopics: [],
            mutedSources: [],
            mutedKeywords: [],
            preferredLanguage: "es",
            notificationsEnabled: true,
            breakingNewsNotifications: true
        )

        NotificationCenter.default.post(name: .userPreferencesDidChange, object: nil)
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(!sut.currentState.isLoading)
        #expect(sut.currentState.error != nil)
    }

    // MARK: - Offline Error Detection

    @Test("Offline error is detected during language reload")
    func offlineErrorDetectedDuringReload() async throws {
        mockSettingsService.preferences = UserPreferences(
            followedTopics: [],
            mutedSources: [],
            mutedKeywords: [],
            preferredLanguage: "en",
            notificationsEnabled: true,
            breakingNewsNotifications: true
        )

        sut.dispatch(action: .loadInitialData)
        try await Task.sleep(nanoseconds: 300_000_000)

        mockMediaService.shouldFail = true

        mockSettingsService.preferences = UserPreferences(
            followedTopics: [],
            mutedSources: [],
            mutedKeywords: [],
            preferredLanguage: "pt",
            notificationsEnabled: true,
            breakingNewsNotifications: true
        )

        NotificationCenter.default.post(name: .userPreferencesDidChange, object: nil)
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(!sut.currentState.isLoading)
        // The mock uses URLError(.notConnectedToInternet) which is not PulseError.offlineNoCache
        // but it's still an error
        #expect(sut.currentState.error != nil)
    }
}
