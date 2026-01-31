import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("FeedViewModel Tests")
@MainActor
struct FeedViewModelTests {
    let mockFeedService: MockFeedService
    let mockNewsService: MockNewsService
    let serviceLocator: ServiceLocator
    let sut: FeedViewModel

    init() {
        mockFeedService = MockFeedService()
        mockNewsService = MockNewsService()
        serviceLocator = ServiceLocator()

        serviceLocator.register(FeedService.self, instance: mockFeedService)
        serviceLocator.register(NewsService.self, instance: mockNewsService)

        sut = FeedViewModel(serviceLocator: serviceLocator)
    }

    @Test("Initial view state matches interactor initial state")
    func initialViewState() async throws {
        // Wait for initial binding to propagate
        try await waitForStateUpdate()

        let state = sut.viewState
        // Initial state shows processing animation (articles load then auto-generate)
        #expect(state.displayState == .processing(phase: .generating))
        #expect(state.sourceArticles.isEmpty)
        #expect(state.digest == nil)
    }

    @Test("onAppear event dispatches loadData")
    func onAppearLoadsData() async {
        mockNewsService.topHeadlinesResult = .success(Article.mockArticles)

        sut.handle(event: .onAppear)

        // Wait for source articles to be loaded
        let success = await waitForCondition(timeout: 2_000_000_000) { [sut] in
            !sut.viewState.sourceArticles.isEmpty
        }
        #expect(success)
    }

    @Test("onRetryTapped event triggers digest generation")
    func onRetryRetries() async {
        mockNewsService.topHeadlinesResult = .success(Article.mockArticles)
        mockFeedService.loadDelay = 0.01
        mockFeedService.generateDelay = 0.01

        // First load data
        sut.handle(event: .onAppear)

        // Wait for articles to load
        let articlesLoaded = await waitForCondition(timeout: 2_000_000_000) { [sut] in
            !sut.viewState.sourceArticles.isEmpty
        }
        #expect(articlesLoaded)

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
        mockNewsService.topHeadlinesResult = .success(Article.mockArticles)

        sut.handle(event: .onAppear)

        // Wait for articles to load
        let articlesLoaded = await waitForCondition(timeout: 2_000_000_000) { [sut] in
            !sut.viewState.sourceArticles.isEmpty
        }
        #expect(articlesLoaded)

        let article = try #require(Article.mockArticles.first)

        sut.handle(event: .onArticleTapped(article))

        // Wait for async state update
        try await waitForStateUpdate()

        let state = sut.viewState
        #expect(state.selectedArticle?.id == article.id)
    }

    @Test("onArticleNavigated event clears selection")
    func onArticleNavigatedClears() async throws {
        mockNewsService.topHeadlinesResult = .success(Article.mockArticles)

        sut.handle(event: .onAppear)

        // Wait for articles to load
        let articlesLoaded = await waitForCondition(timeout: 2_000_000_000) { [sut] in
            !sut.viewState.sourceArticles.isEmpty
        }
        #expect(articlesLoaded)

        let article = try #require(Article.mockArticles.first)

        sut.handle(event: .onArticleTapped(article))
        try await waitForStateUpdate()

        sut.handle(event: .onArticleNavigated)
        try await waitForStateUpdate()

        let state = sut.viewState
        #expect(state.selectedArticle == nil)
    }

    @Test("Empty articles from API shows empty state")
    func emptyArticlesShowsEmptyState() async {
        mockNewsService.topHeadlinesResult = .success([])
        mockNewsService.categoryHeadlinesResult = .success([])

        sut.handle(event: .onAppear)

        // Wait for display state to become empty or error (due to no articles)
        let success = await waitForCondition(timeout: 2_000_000_000) { [sut] in
            sut.viewState.displayState == .empty || sut.viewState.displayState == .error
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
        mockNewsService.topHeadlinesResult = .success(Article.mockArticles)

        sut.handle(event: .onAppear)

        try await waitForStateUpdate()

        let state = sut.viewState
        #expect(state.displayState == .completed)
        #expect(state.digest?.summary == "Cached summary")
    }

    @Test("View state updates are published")
    func viewStateUpdatesPublished() async {
        var states: [FeedViewState] = []
        var cancellables = Set<AnyCancellable>()

        sut.$viewState
            .sink { states.append($0) }
            .store(in: &cancellables)

        mockNewsService.topHeadlinesResult = .success(Article.mockArticles)

        sut.handle(event: .onAppear)

        // Wait for state updates
        let success = await waitForCondition(timeout: 2_000_000_000) { states.count > 1 }

        #expect(success, "View state should update multiple times")
    }
}
