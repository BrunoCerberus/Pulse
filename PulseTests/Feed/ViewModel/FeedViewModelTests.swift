import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("FeedViewModel Tests")
@MainActor
struct FeedViewModelTests {
    let mockFeedService: MockFeedService
    let mockStorageService: MockStorageService
    let serviceLocator: ServiceLocator
    let sut: FeedViewModel

    init() {
        mockFeedService = MockFeedService()
        mockStorageService = MockStorageService()
        serviceLocator = ServiceLocator()

        serviceLocator.register(FeedService.self, instance: mockFeedService)
        serviceLocator.register(StorageService.self, instance: mockStorageService)

        sut = FeedViewModel(serviceLocator: serviceLocator)
    }

    @Test("Initial view state matches interactor initial state")
    func initialViewState() async throws {
        // Wait for initial binding to propagate
        try await waitForStateUpdate()

        let state = sut.viewState
        // Initial state with idle generationState and empty history maps to idle
        #expect(state.displayState == .idle)
        #expect(state.sourceArticles.isEmpty)
        #expect(state.digest == nil)
    }

    @Test("onAppear event dispatches loadData")
    func onAppearLoadsData() async {
        mockStorageService.readingHistory = Article.mockArticles

        sut.handle(event: .onAppear)

        // Wait for source articles to be loaded
        let success = await waitForCondition(timeout: 1_000_000_000) { [sut] in
            sut.viewState.sourceArticles.count == Article.mockArticles.count
        }
        #expect(success)
    }

    @Test("onRetryTapped event triggers digest generation")
    func onRetryRetries() async throws {
        mockStorageService.readingHistory = Article.mockArticles
        mockFeedService.loadDelay = 0.01
        mockFeedService.generateDelay = 0.01

        // First load data
        sut.handle(event: .onAppear)
        try await waitForStateUpdate()

        // Now retry should trigger generation
        sut.handle(event: .onRetryTapped)

        // Wait for generation to be in progress or completed
        let success = await waitForCondition(timeout: 2_000_000_000) { [sut] in
            let state = sut.viewState.displayState
            if case .processing = state { return true }
            if case .completed = state { return true }
            return false
        }
        #expect(success)
    }

    @Test("onArticleTapped event selects article")
    func onArticleTappedSelects() async throws {
        mockStorageService.readingHistory = Article.mockArticles

        sut.handle(event: .onAppear)
        try await waitForStateUpdate()

        let article = try #require(Article.mockArticles.first)

        sut.handle(event: .onArticleTapped(article))

        // Wait for async state update
        try await waitForStateUpdate()

        let state = sut.viewState
        #expect(state.selectedArticle?.id == article.id)
    }

    @Test("onArticleNavigated event clears selection")
    func onArticleNavigatedClears() async throws {
        mockStorageService.readingHistory = Article.mockArticles

        sut.handle(event: .onAppear)
        try await waitForStateUpdate()

        let article = try #require(Article.mockArticles.first)

        sut.handle(event: .onArticleTapped(article))
        try await waitForStateUpdate()

        sut.handle(event: .onArticleNavigated)
        try await waitForStateUpdate()

        let state = sut.viewState
        #expect(state.selectedArticle == nil)
    }

    @Test("Empty reading history shows empty state")
    func emptyHistoryShowsEmptyState() async {
        mockStorageService.readingHistory = []

        sut.handle(event: .onAppear)

        // Wait for display state to become empty
        let success = await waitForCondition(timeout: 1_000_000_000) { [sut] in
            sut.viewState.displayState == .empty
        }
        #expect(success)
    }

    @Test("Cached digest shows completed state immediately")
    func cachedDigestShowsCompleted() async throws {
        let cachedDigest = DailyDigest(
            id: "cached",
            summary: "Cached summary",
            sourceArticles: Article.mockArticles,
            generatedAt: Date()
        )
        mockFeedService.cachedDigest = cachedDigest
        mockStorageService.readingHistory = Article.mockArticles

        sut.handle(event: .onAppear)

        try await waitForStateUpdate()

        let state = sut.viewState
        #expect(state.displayState == .completed)
        #expect(state.digest?.summary == "Cached summary")
    }

    @Test("View state updates are published")
    func viewStateUpdatesPublished() async throws {
        var states: [FeedViewState] = []
        var cancellables = Set<AnyCancellable>()

        sut.$viewState
            .sink { states.append($0) }
            .store(in: &cancellables)

        mockStorageService.readingHistory = Article.mockArticles

        sut.handle(event: .onAppear)

        try await waitForStateUpdate()

        #expect(states.count > 1, "View state should update multiple times")
    }
}
