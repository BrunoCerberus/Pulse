import EntropyCore
import Foundation
@testable import Pulse
import Testing

/// Covers the persisted Home category filter: following a topic makes it the
/// active filter, unfollowing it falls back to "All", and the last selection is
/// restored on a cold launch.
@Suite("Home Category Persistence Tests")
@MainActor
struct HomeCategoryPersistenceTests {
    let mockNewsService: MockNewsService
    let mockSettingsService: MockSettingsService
    let defaults: UserDefaults
    let sut: HomeDomainInteractor

    init() {
        mockNewsService = MockNewsService()
        mockSettingsService = MockSettingsService()
        mockNewsService.topHeadlinesResult = .success(Article.mockArticles)
        mockNewsService.breakingNewsResult = .success(Array(Article.mockArticles.prefix(2)))
        mockNewsService.categoryHeadlinesResult = .success(Article.mockArticles)

        // Isolated store per test so the persisted key can't race other suites.
        defaults = UserDefaults(suiteName: "test.home.category.\(UUID().uuidString)")!

        let serviceLocator = ServiceLocator()
        serviceLocator.register(NewsService.self, instance: mockNewsService)
        serviceLocator.register(StorageService.self, instance: MockStorageService())
        serviceLocator.register(SettingsService.self, instance: mockSettingsService)
        serviceLocator.register(AnalyticsService.self, instance: MockAnalyticsService())

        sut = HomeDomainInteractor(serviceLocator: serviceLocator, defaults: defaults)
    }

    private var persistedCategory: String? {
        defaults.string(forKey: HomeDomainInteractor.selectedCategoryDefaultsKey)
    }

    private func preferences(followedTopics: [NewsCategory]) -> UserPreferences {
        UserPreferences(
            followedTopics: followedTopics,
            mutedSources: [],
            mutedKeywords: [],
            preferredLanguage: "en",
            notificationsEnabled: true,
            breakingNewsNotifications: true,
        )
    }

    @Test("Following a topic makes it the selected category")
    func followingTopicSelectsIt() async throws {
        mockSettingsService.preferences = preferences(followedTopics: [])

        sut.dispatch(action: .toggleTopic(.technology))
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(sut.currentState.selectedCategory == .technology)
        #expect(persistedCategory == NewsCategory.technology.rawValue)
    }

    @Test("Unfollowing the active category falls back to All")
    func unfollowingActiveCategoryFallsBackToAll() async throws {
        mockSettingsService.preferences = preferences(followedTopics: [.technology])
        sut.dispatch(action: .selectCategory(.technology))
        try await Task.sleep(nanoseconds: 500_000_000)
        #expect(sut.currentState.selectedCategory == .technology)

        sut.dispatch(action: .toggleTopic(.technology))
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(sut.currentState.selectedCategory == nil)
        #expect(persistedCategory == nil)
    }

    @Test("Unfollowing an inactive topic keeps the current filter")
    func unfollowingInactiveTopicKeepsFilter() async throws {
        mockSettingsService.preferences = preferences(followedTopics: [.technology, .sports])
        sut.dispatch(action: .selectCategory(.technology))
        try await Task.sleep(nanoseconds: 500_000_000)

        sut.dispatch(action: .toggleTopic(.sports))
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(sut.currentState.selectedCategory == .technology)
        #expect(persistedCategory == NewsCategory.technology.rawValue)
    }

    @Test("Initial load restores the persisted category when still followed")
    func initialLoadRestoresPersistedCategory() async throws {
        defaults.set(NewsCategory.technology.rawValue, forKey: HomeDomainInteractor.selectedCategoryDefaultsKey)
        mockSettingsService.preferences = preferences(followedTopics: [.technology])

        sut.dispatch(action: .loadInitialData)
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(sut.currentState.selectedCategory == .technology)
        // The first fetch went straight to the category endpoint, not "All".
        #expect(!mockNewsService.fetchedCategoryHeadlinesLanguages.isEmpty)
        #expect(sut.currentState.breakingNews.isEmpty)
    }

    @Test("Initial load ignores a persisted category the user no longer follows")
    func initialLoadIgnoresUnfollowedPersistedCategory() async throws {
        defaults.set(NewsCategory.sports.rawValue, forKey: HomeDomainInteractor.selectedCategoryDefaultsKey)
        mockSettingsService.preferences = preferences(followedTopics: [.technology])

        sut.dispatch(action: .loadInitialData)
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(sut.currentState.selectedCategory == nil)
        #expect(!sut.currentState.breakingNews.isEmpty)
    }
}
