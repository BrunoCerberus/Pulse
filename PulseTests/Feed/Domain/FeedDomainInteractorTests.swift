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
    let mockNetworkMonitor: MockNetworkMonitorService
    let mockAnalyticsService: MockAnalyticsService
    let serviceLocator: ServiceLocator
    let sut: FeedDomainInteractor

    init() {
        mockFeedService = MockFeedService()
        mockNewsService = MockNewsService()
        mockNetworkMonitor = MockNetworkMonitorService()
        mockAnalyticsService = MockAnalyticsService()
        serviceLocator = ServiceLocator()

        serviceLocator.register(FeedService.self, instance: mockFeedService)
        serviceLocator.register(NewsService.self, instance: mockNewsService)
        serviceLocator.register(NetworkMonitorService.self, instance: mockNetworkMonitor)
        serviceLocator.register(AnalyticsService.self, instance: mockAnalyticsService)

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

    // MARK: - Offline Tests

    @Test("Offline error sets isOfflineError to true")
    func offlineErrorSetsFlag() async {
        mockNetworkMonitor.simulateOffline()
        mockNewsService.topHeadlinesResult = .failure(URLError(.notConnectedToInternet))
        mockNewsService.categoryHeadlinesResult = .failure(URLError(.notConnectedToInternet))

        sut.dispatch(action: .loadInitialData)

        let success = await waitForCondition(timeout: 2_000_000_000) { [sut] in
            sut.currentState.isOfflineError
        }

        #expect(success, "Should set isOfflineError when offline")
        let state = sut.currentState
        #expect(state.isOfflineError)
        if case .error = state.generationState {
            // Expected
        } else {
            Issue.record("Should be in error state when offline")
        }
    }

    @Test("Successful article load resets isOfflineError")
    func successfulLoadResetsOfflineError() async {
        // First trigger offline error
        mockNetworkMonitor.simulateOffline()
        mockNewsService.topHeadlinesResult = .failure(URLError(.notConnectedToInternet))
        mockNewsService.categoryHeadlinesResult = .failure(URLError(.notConnectedToInternet))

        sut.dispatch(action: .loadInitialData)

        let offlineSet = await waitForCondition(timeout: 2_000_000_000) { [sut] in
            sut.currentState.isOfflineError
        }
        #expect(offlineSet, "Should be offline first")

        // Now simulate coming back online and retrying
        mockNetworkMonitor.simulateOnline()
        mockNewsService.topHeadlinesResult = .success(Article.mockArticles)
        mockNewsService.categoryHeadlinesResult = nil

        sut.dispatch(action: .retryAfterError)

        let recovered = await waitForCondition(timeout: 2_000_000_000) { [sut] in
            !sut.currentState.isOfflineError && sut.currentState.hasLoadedInitialData
        }

        #expect(recovered, "Should recover from offline state")
        #expect(!sut.currentState.isOfflineError)
    }

    @Test("Retry after error resets state and re-fetches")
    func retryAfterErrorResetsState() {
        mockNewsService.topHeadlinesResult = .success(Article.mockArticles)

        sut.dispatch(action: .retryAfterError)

        #expect(!sut.currentState.hasLoadedInitialData)
        #expect(!sut.currentState.isOfflineError)

        if case .loadingArticles = sut.currentState.generationState {
            // Expected
        } else {
            Issue.record("Should be in loadingArticles state after retry")
        }
    }
}

// MARK: - Analytics Tests

extension FeedDomainInteractorTests {
    @Test("Logs screen_view on loadInitialData")
    func logsScreenViewOnLoad() async throws {
        sut.dispatch(action: .loadInitialData)
        try await Task.sleep(nanoseconds: 500_000_000)

        let screenEvents = mockAnalyticsService.loggedEvents.filter { $0.name == "screen_view" }
        #expect(screenEvents.count == 1)
        #expect(screenEvents.first?.parameters?["screen_name"] as? String == "feed")
    }

    @Test("Logs digest_generated success on digestCompleted")
    func logsDigestGeneratedSuccess() {
        let digest = DailyDigest(
            id: "test",
            summary: "Test summary",
            sourceArticles: Article.mockArticles,
            generatedAt: Date()
        )
        sut.dispatch(action: .digestCompleted(digest))

        let digestEvents = mockAnalyticsService.loggedEvents.filter { $0.name == "digest_generated" }
        #expect(digestEvents.count == 1)
        #expect(digestEvents.first?.parameters?["success"] as? Bool == true)
    }

    @Test("Logs digest_generated failure and records error on digestFailed")
    func logsDigestGeneratedFailure() {
        sut.dispatch(action: .digestFailed("Generation failed"))

        let digestEvents = mockAnalyticsService.loggedEvents.filter { $0.name == "digest_generated" }
        #expect(digestEvents.count == 1)
        #expect(digestEvents.first?.parameters?["success"] as? Bool == false)
        #expect(mockAnalyticsService.recordedErrors.count == 1)
    }
}
