import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("FeedDomainInteractor Tests")
@MainActor
struct FeedDomainInteractorTests {
    let mockFeedService: MockFeedService
    let mockNewsService: MockNewsService
    let serviceLocator: ServiceLocator
    let sut: FeedDomainInteractor

    init() {
        mockFeedService = MockFeedService()
        mockNewsService = MockNewsService()
        serviceLocator = ServiceLocator()

        serviceLocator.register(FeedService.self, instance: mockFeedService)
        serviceLocator.register(NewsService.self, instance: mockNewsService)

        sut = FeedDomainInteractor(serviceLocator: serviceLocator)
    }

    @Test("Initial state is correct")
    func initialState() {
        let state = sut.currentState
        #expect(state.latestArticles.isEmpty)
        #expect(state.currentDigest == nil)
        #expect(state.streamingText.isEmpty)
        #expect(!state.hasLoadedInitialData)
        #expect(state.selectedArticle == nil)
        // Initial state starts with loadingArticles to show processing animation immediately
        if case .loadingArticles = state.generationState {
            // Expected
        } else {
            Issue.record("Initial state should be loadingArticles")
        }
    }

    @Test("Load data fetches latest articles from API")
    func loadDataFetchesArticles() async {
        mockNewsService.topHeadlinesResult = .success(Article.mockArticles)

        sut.dispatch(action: .loadInitialData)

        // Wait for async article fetching to complete
        let success = await waitForCondition(timeout: 2_000_000_000) { [sut] in
            sut.currentState.hasLoadedInitialData && !sut.currentState.latestArticles.isEmpty
        }

        #expect(success, "Should load initial data with articles")
        let state = sut.currentState
        #expect(state.hasLoadedInitialData)
        #expect(!state.latestArticles.isEmpty)
    }

    @Test("Load data with cached digest uses cache")
    func loadDataUsesCachedDigest() async {
        let cachedDigest = DailyDigest(
            id: "cached",
            summary: "Cached summary",
            sourceArticles: Article.mockArticles,
            generatedAt: Date()
        )
        mockFeedService.cachedDigest = cachedDigest
        mockNewsService.topHeadlinesResult = .success(Article.mockArticles)

        sut.dispatch(action: .loadInitialData)

        // Wait for cached digest to appear (includes 300ms animation delay)
        let success = await waitForCondition(timeout: 2_000_000_000) { [sut] in
            sut.currentState.currentDigest != nil
        }

        #expect(success, "Cached digest should be loaded")
        let state = sut.currentState
        #expect(state.currentDigest?.id == "cached")
    }

    @Test("Load data with API failure shows error state")
    func loadDataAPIFailure() async {
        mockNewsService.topHeadlinesResult = .failure(URLError(.notConnectedToInternet))
        mockNewsService.categoryHeadlinesResult = .failure(URLError(.notConnectedToInternet))

        sut.dispatch(action: .loadInitialData)

        // Wait for async article fetching to complete (may result in empty due to all failures)
        let success = await waitForCondition(timeout: 2_000_000_000) { [sut] in
            sut.currentState.hasLoadedInitialData ||
                sut.currentState.generationState == .error("Unable to fetch news")
        }

        #expect(success, "Should handle API failure")
    }

    @Test("Generate digest triggers generation state")
    func generateDigestStreaming() async throws {
        mockNewsService.topHeadlinesResult = .success(Article.mockArticles)
        mockFeedService.loadDelay = 0.01 // Speed up for tests
        mockFeedService.generateDelay = 0.01

        sut.dispatch(action: .loadInitialData)

        // Wait for articles to load
        let articlesLoaded = await waitForCondition(timeout: 2_000_000_000) { [sut] in
            !sut.currentState.latestArticles.isEmpty
        }
        #expect(articlesLoaded, "Articles should be loaded")

        sut.dispatch(action: .generateDigest)

        // Wait briefly for generation to start
        try await Task.sleep(nanoseconds: 100_000_000)

        let state = sut.currentState
        // Should be in some generation-related state
        let isInGenerationFlow = switch state.generationState {
        case .generating, .completed:
            true
        default:
            false
        }
        #expect(isInGenerationFlow, "Should be generating or completed")
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
    func preloadTriggeredWithoutCache() async {
        mockFeedService.cachedDigest = nil
        mockFeedService.loadDelay = 0.01
        mockNewsService.topHeadlinesResult = .success(Article.mockArticles)

        sut.dispatch(action: .loadInitialData)

        // Wait for preload to be triggered
        let success = await waitForCondition(timeout: 2_000_000_000) { [mockFeedService] in
            mockFeedService.loadModelCallCount > 0
        }

        #expect(success, "Model preload should be triggered")
    }

    @Test("Preload model skipped when cached digest exists")
    func preloadSkippedWithCachedDigest() async throws {
        let cachedDigest = DailyDigest(
            id: "cached",
            summary: "Cached summary",
            sourceArticles: Article.mockArticles,
            generatedAt: Date()
        )
        mockFeedService.cachedDigest = cachedDigest
        mockNewsService.topHeadlinesResult = .success(Article.mockArticles)

        sut.dispatch(action: .loadInitialData)
        try await waitForStateUpdate()

        #expect(mockFeedService.loadModelCallCount == 0, "Model preload should be skipped when cache exists")
    }

    @Test("Preload failure does not prevent generation")
    func preloadFailureAllowsGeneration() async {
        mockFeedService.cachedDigest = nil
        mockFeedService.shouldFail = true
        mockFeedService.loadDelay = 0.01
        mockNewsService.topHeadlinesResult = .success(Article.mockArticles)

        sut.dispatch(action: .loadInitialData)

        // Wait for initial data to load
        let success = await waitForCondition(timeout: 2_000_000_000) { [sut] in
            sut.currentState.hasLoadedInitialData
        }

        // Even with preload failure, state should be ready for generation attempt
        #expect(success, "Should still load initial data despite preload failure")
    }
}
