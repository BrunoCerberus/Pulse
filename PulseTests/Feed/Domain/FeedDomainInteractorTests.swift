import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("FeedDomainInteractor Tests")
@MainActor
struct FeedDomainInteractorTests {
    let mockFeedService: MockFeedService
    let mockStorageService: MockStorageService
    let serviceLocator: ServiceLocator
    let sut: FeedDomainInteractor

    init() {
        mockFeedService = MockFeedService()
        mockStorageService = MockStorageService()
        serviceLocator = ServiceLocator()

        serviceLocator.register(FeedService.self, instance: mockFeedService)
        serviceLocator.register(StorageService.self, instance: mockStorageService)

        sut = FeedDomainInteractor(serviceLocator: serviceLocator)
    }

    @Test("Initial state is correct")
    func initialState() {
        let state = sut.currentState
        #expect(state.readingHistory.isEmpty)
        #expect(state.currentDigest == nil)
        #expect(state.streamingText.isEmpty)
        #expect(!state.hasLoadedInitialData)
        #expect(state.selectedArticle == nil)
        if case .idle = state.generationState {
            // Expected
        } else {
            Issue.record("Initial state should be idle")
        }
    }

    @Test("Load data fetches reading history")
    func loadDataFetchesHistory() async throws {
        mockStorageService.readingHistory = Article.mockArticles

        sut.dispatch(action: .loadInitialData)

        try await waitForStateUpdate()

        let state = sut.currentState
        #expect(state.hasLoadedInitialData)
        #expect(state.readingHistory.count == Article.mockArticles.count)
    }

    @Test("Load data with cached digest uses cache")
    func loadDataUsesCachedDigest() async throws {
        let cachedDigest = DailyDigest(
            id: "cached",
            summary: "Cached summary",
            sourceArticles: [],
            generatedAt: Date()
        )
        mockFeedService.cachedDigest = cachedDigest
        mockStorageService.readingHistory = Article.mockArticles

        sut.dispatch(action: .loadInitialData)

        try await waitForStateUpdate()

        let state = sut.currentState
        #expect(state.currentDigest != nil)
        #expect(state.currentDigest?.id == "cached")
    }

    @Test("Load data with empty history shows empty state")
    func loadDataEmptyHistory() async throws {
        mockStorageService.readingHistory = []

        sut.dispatch(action: .loadInitialData)

        try await waitForStateUpdate()

        let state = sut.currentState
        #expect(state.hasLoadedInitialData)
        #expect(state.readingHistory.isEmpty)
    }

    @Test("Generate digest triggers generation state")
    func generateDigestStreaming() async throws {
        mockStorageService.readingHistory = Article.mockArticles
        mockFeedService.loadDelay = 0.01 // Speed up for tests
        mockFeedService.generateDelay = 0.01

        sut.dispatch(action: .loadInitialData)

        // Wait for reading history to actually be loaded
        let historyLoaded = await waitForCondition {
            !self.sut.currentState.readingHistory.isEmpty && self.sut.currentState.hasLoadedInitialData
        }
        #expect(historyLoaded, "Reading history should be loaded")

        sut.dispatch(action: .generateDigest)

        // Wait for generation state to be set
        let generationStarted = await waitForCondition {
            switch self.sut.currentState.generationState {
            case .generating, .completed:
                return true
            default:
                return false
            }
        }
        #expect(generationStarted, "Should be generating or completed")
    }

    @Test("Select article updates state")
    func selectArticle() {
        let article = Article.mockArticles[0]

        sut.dispatch(action: .selectArticle(article))

        let state = sut.currentState
        #expect(state.selectedArticle?.id == article.id)
    }

    @Test("Clear selection removes selected article")
    func clearSelection() {
        let article = Article.mockArticles[0]

        sut.dispatch(action: .selectArticle(article))
        sut.dispatch(action: .clearSelectedArticle)

        let state = sut.currentState
        #expect(state.selectedArticle == nil)
    }

    @Test("Model status updates propagate to state")
    func modelStatusUpdates() async throws {
        mockFeedService.simulateModelStatus(.loading(progress: 0.5))

        try await waitForStateUpdate()

        let state = sut.currentState
        #expect(state.modelStatus == .loading(progress: 0.5))
    }

    // MARK: - Model Preload Tests

    @Test("Preload model triggered when no cached digest")
    func preloadTriggeredWithoutCache() async throws {
        mockFeedService.cachedDigest = nil
        mockFeedService.loadDelay = 0.01
        mockStorageService.readingHistory = Article.mockArticles

        sut.dispatch(action: .loadInitialData)
        try await waitForStateUpdate()

        #expect(mockFeedService.loadModelCallCount > 0, "Model preload should be triggered")
    }

    @Test("Preload model skipped when cached digest exists")
    func preloadSkippedWithCachedDigest() async throws {
        let cachedDigest = DailyDigest(
            id: "cached",
            summary: "Cached summary",
            sourceArticles: [],
            generatedAt: Date()
        )
        mockFeedService.cachedDigest = cachedDigest
        mockStorageService.readingHistory = Article.mockArticles

        sut.dispatch(action: .loadInitialData)
        try await waitForStateUpdate()

        #expect(mockFeedService.loadModelCallCount == 0, "Model preload should be skipped when cache exists")
    }

    @Test("Preload failure does not prevent generation")
    func preloadFailureAllowsGeneration() async throws {
        mockFeedService.cachedDigest = nil
        mockFeedService.shouldFail = true
        mockFeedService.loadDelay = 0.01
        mockStorageService.readingHistory = Article.mockArticles

        sut.dispatch(action: .loadInitialData)
        try await waitForStateUpdate()

        // Even with preload failure, state should be ready for generation attempt
        let state = sut.currentState
        #expect(state.hasLoadedInitialData, "Should still load initial data despite preload failure")
    }
}
