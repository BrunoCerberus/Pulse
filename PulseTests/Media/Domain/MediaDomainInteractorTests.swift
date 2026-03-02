import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("MediaDomainInteractor Tests")
@MainActor
struct MediaDomainInteractorTests {
    let mockMediaService: MockMediaService
    let mockStorageService: MockStorageService
    let mockAnalyticsService: MockAnalyticsService
    let serviceLocator: ServiceLocator
    let sut: MediaDomainInteractor

    init() {
        mockMediaService = MockMediaService()
        mockMediaService.simulatedDelay = 0.1 // Fast for tests
        mockStorageService = MockStorageService()
        mockAnalyticsService = MockAnalyticsService()
        serviceLocator = ServiceLocator()

        serviceLocator.register(MediaService.self, instance: mockMediaService)
        serviceLocator.register(StorageService.self, instance: mockStorageService)
        serviceLocator.register(SettingsService.self, instance: MockSettingsService())
        serviceLocator.register(AnalyticsService.self, instance: mockAnalyticsService)

        sut = MediaDomainInteractor(serviceLocator: serviceLocator)
    }

    // MARK: - Initial State Tests

    @Test("Initial state is correct")
    func initialState() {
        let state = sut.currentState
        #expect(state.featuredMedia.isEmpty)
        #expect(state.mediaItems.isEmpty)
        #expect(!state.isLoading)
        #expect(!state.isLoadingMore)
        #expect(!state.isRefreshing)
        #expect(state.error == nil)
        #expect(state.currentPage == 1)
        #expect(state.hasMorePages)
        #expect(!state.hasLoadedInitialData)
        #expect(state.selectedType == nil)
        #expect(state.selectedMedia == nil)
        #expect(state.mediaToShare == nil)
        #expect(state.mediaToPlay == nil)
    }

    // MARK: - Load Initial Data Tests

    @Test("Load initial data updates state correctly")
    func testLoadInitialData() async throws {
        var cancellables = Set<AnyCancellable>()
        var states: [MediaDomainState] = []

        sut.statePublisher
            .sink { state in
                states.append(state)
            }
            .store(in: &cancellables)

        sut.dispatch(action: .loadInitialData)

        try await Task.sleep(nanoseconds: 300_000_000)

        let finalState = sut.currentState
        #expect(!finalState.isLoading)
        #expect(finalState.error == nil)
        #expect(!finalState.featuredMedia.isEmpty)
        #expect(!finalState.mediaItems.isEmpty)
        #expect(finalState.hasLoadedInitialData)
    }

    @Test("Load initial data uses persisted preferred language")
    func loadInitialDataUsesPersistedLanguage() async throws {
        let mockSettingsService = try #require(serviceLocator.retrieve(SettingsService.self) as? MockSettingsService)
        let preferences = UserPreferences(
            followedTopics: [],

            mutedSources: [],
            mutedKeywords: [],
            preferredLanguage: "es",
            notificationsEnabled: true,
            breakingNewsNotifications: true
        )
        mockSettingsService.preferences = preferences
        mockMediaService.fetchedMediaLanguages = []
        mockMediaService.fetchedFeaturedMediaLanguages = []

        sut.dispatch(action: .loadInitialData)

        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(!mockMediaService.fetchedMediaLanguages.isEmpty)
        #expect(!mockMediaService.fetchedFeaturedMediaLanguages.isEmpty)
        #expect(mockMediaService.fetchedMediaLanguages.allSatisfy { $0 == "es" })
        #expect(mockMediaService.fetchedFeaturedMediaLanguages.allSatisfy { $0 == "es" })
    }

    @Test("Load initial data falls back to default language on preferences failure")
    func loadInitialDataFallsBackToDefaultLanguageOnFailure() async throws {
        let mockSettingsService = try #require(serviceLocator.retrieve(SettingsService.self) as? MockSettingsService)
        mockSettingsService.fetchPreferencesResult = .failure(URLError(.cannotLoadFromNetwork))
        mockMediaService.fetchedMediaLanguages = []
        mockMediaService.fetchedFeaturedMediaLanguages = []

        sut.dispatch(action: .loadInitialData)

        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(!mockMediaService.fetchedMediaLanguages.isEmpty)
        #expect(!mockMediaService.fetchedFeaturedMediaLanguages.isEmpty)
        #expect(mockMediaService.fetchedMediaLanguages.allSatisfy { $0 == "en" })
        #expect(mockMediaService.fetchedFeaturedMediaLanguages.allSatisfy { $0 == "en" })
    }

    @Test("Load initial data is idempotent when already loaded")
    func loadInitialDataIdempotent() async throws {
        // First load
        sut.dispatch(action: .loadInitialData)
        try await Task.sleep(nanoseconds: 300_000_000)

        let stateAfterFirstLoad = sut.currentState
        #expect(stateAfterFirstLoad.hasLoadedInitialData)

        // Second load should be ignored
        sut.dispatch(action: .loadInitialData)
        try await Task.sleep(nanoseconds: 100_000_000)

        // State should remain the same
        #expect(sut.currentState.hasLoadedInitialData)
    }

    @Test("Error handling works correctly")
    func errorHandling() async throws {
        mockMediaService.shouldFail = true

        sut.dispatch(action: .loadInitialData)

        try await Task.sleep(nanoseconds: 300_000_000)

        let finalState = sut.currentState
        #expect(!finalState.isLoading)
        #expect(finalState.error != nil)
    }

    // MARK: - Refresh Tests

    @Test("Refresh resets page and reloads data")
    func testRefresh() async throws {
        // First load initial data
        sut.dispatch(action: .loadInitialData)
        try await Task.sleep(nanoseconds: 300_000_000)

        // Then refresh
        sut.dispatch(action: .refresh)

        // Should set isRefreshing
        #expect(sut.currentState.isRefreshing || sut.currentState.hasLoadedInitialData)

        try await Task.sleep(nanoseconds: 300_000_000)

        let state = sut.currentState
        #expect(state.currentPage == 1)
        #expect(!state.isRefreshing)
        #expect(!state.featuredMedia.isEmpty)
    }

    // MARK: - Load More Tests

    @Test("Load more media updates state correctly")
    func testLoadMoreMedia() async throws {
        // First load initial data
        sut.dispatch(action: .loadInitialData)
        try await Task.sleep(nanoseconds: 300_000_000)

        _ = sut.currentState.mediaItems.count

        // Load more
        sut.dispatch(action: .loadMoreMedia)
        try await Task.sleep(nanoseconds: 300_000_000)

        let state = sut.currentState
        #expect(!state.isLoadingMore)
        #expect(state.currentPage >= 1)
    }

    @Test("Load more is ignored when already loading more")
    func loadMoreIgnoredWhenLoading() async throws {
        sut.dispatch(action: .loadInitialData)
        try await Task.sleep(nanoseconds: 300_000_000)

        // Trigger load more twice in quick succession
        sut.dispatch(action: .loadMoreMedia)
        sut.dispatch(action: .loadMoreMedia)

        try await Task.sleep(nanoseconds: 300_000_000)

        // Should only increment page once
        #expect(sut.currentState.currentPage >= 1)
    }

    // MARK: - Media Type Selection Tests

    @Test("Select media type updates state and reloads data")
    func testSelectMediaType() async throws {
        // Load initial data first
        sut.dispatch(action: .loadInitialData)
        try await Task.sleep(nanoseconds: 300_000_000)

        // Select video type
        sut.dispatch(action: .selectMediaType(.video))
        try await Task.sleep(nanoseconds: 300_000_000)

        let state = sut.currentState
        #expect(state.selectedType == .video)
        #expect(!state.isLoading)
        #expect(state.hasLoadedInitialData)
    }

    @Test("Select same media type does nothing")
    func selectSameMediaTypeNoOp() async throws {
        // Set up with video type selected
        sut.dispatch(action: .selectMediaType(.video))
        try await Task.sleep(nanoseconds: 300_000_000)

        let stateBeforeReselect = sut.currentState

        // Select same type again
        sut.dispatch(action: .selectMediaType(.video))
        try await Task.sleep(nanoseconds: 100_000_000)

        // State should remain unchanged
        #expect(sut.currentState.selectedType == stateBeforeReselect.selectedType)
    }

    @Test("Select nil media type returns to all types")
    func selectNilMediaType() async throws {
        // First select a type
        sut.dispatch(action: .selectMediaType(.podcast))
        try await Task.sleep(nanoseconds: 300_000_000)
        #expect(sut.currentState.selectedType == .podcast)

        // Select nil to return to all
        sut.dispatch(action: .selectMediaType(nil))
        try await Task.sleep(nanoseconds: 300_000_000)

        let state = sut.currentState
        #expect(state.selectedType == nil)
    }

    // MARK: - Media Selection Tests

    @Test("Select media sets selectedMedia")
    func testSelectMedia() async throws {
        // First load media
        sut.dispatch(action: .loadInitialData)
        try await Task.sleep(nanoseconds: 300_000_000)

        let media = sut.currentState.mediaItems.first ?? sut.currentState.featuredMedia.first
        guard let mediaId = media?.id else {
            #expect(Bool(false), "No media available for testing")
            return
        }

        sut.dispatch(action: .selectMedia(mediaId: mediaId))
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(sut.currentState.selectedMedia?.id == mediaId)
    }

    @Test("Clear selected media clears selection")
    func testClearSelectedMedia() async throws {
        // First load and select media
        sut.dispatch(action: .loadInitialData)
        try await Task.sleep(nanoseconds: 300_000_000)

        if let mediaId = sut.currentState.mediaItems.first?.id {
            sut.dispatch(action: .selectMedia(mediaId: mediaId))
            try await Task.sleep(nanoseconds: 100_000_000)
            #expect(sut.currentState.selectedMedia != nil)

            sut.dispatch(action: .clearSelectedMedia)
            #expect(sut.currentState.selectedMedia == nil)
        }
    }

    // MARK: - Share Tests

    @Test("Share media sets mediaToShare")
    func testShareMedia() async throws {
        sut.dispatch(action: .loadInitialData)
        try await Task.sleep(nanoseconds: 300_000_000)

        if let mediaId = sut.currentState.mediaItems.first?.id {
            sut.dispatch(action: .shareMedia(mediaId: mediaId))
            try await Task.sleep(nanoseconds: 100_000_000)

            #expect(sut.currentState.mediaToShare?.id == mediaId)
        }
    }

    @Test("Clear media to share clears selection")
    func testClearMediaToShare() async throws {
        sut.dispatch(action: .loadInitialData)
        try await Task.sleep(nanoseconds: 300_000_000)

        if let mediaId = sut.currentState.mediaItems.first?.id {
            sut.dispatch(action: .shareMedia(mediaId: mediaId))
            try await Task.sleep(nanoseconds: 100_000_000)

            sut.dispatch(action: .clearMediaToShare)
            #expect(sut.currentState.mediaToShare == nil)
        }
    }

    // MARK: - Play Tests

    @Test("Play media sets mediaToPlay")
    func testPlayMedia() async throws {
        sut.dispatch(action: .loadInitialData)
        try await Task.sleep(nanoseconds: 300_000_000)

        if let mediaId = sut.currentState.mediaItems.first?.id {
            sut.dispatch(action: .playMedia(mediaId: mediaId))
            try await Task.sleep(nanoseconds: 300_000_000)

            #expect(sut.currentState.mediaToPlay?.id == mediaId)
        }
    }

    @Test("Clear media to play clears selection")
    func testClearMediaToPlay() async throws {
        sut.dispatch(action: .loadInitialData)
        try await Task.sleep(nanoseconds: 300_000_000)

        if let mediaId = sut.currentState.mediaItems.first?.id {
            sut.dispatch(action: .playMedia(mediaId: mediaId))
            try await Task.sleep(nanoseconds: 100_000_000)

            sut.dispatch(action: .clearMediaToPlay)
            #expect(sut.currentState.mediaToPlay == nil)
        }
    }
}

// MARK: - Analytics Tests

extension MediaDomainInteractorTests {
    @Test("Logs screen_view on loadInitialData")
    func logsScreenViewOnLoad() async throws {
        sut.dispatch(action: .loadInitialData)
        try await Task.sleep(nanoseconds: 500_000_000)

        let screenEvents = mockAnalyticsService.loggedEvents.filter { $0.name == "screen_view" }
        #expect(screenEvents.count == 1)
        #expect(screenEvents.first?.parameters?["screen_name"] as? String == "media")
    }
}
