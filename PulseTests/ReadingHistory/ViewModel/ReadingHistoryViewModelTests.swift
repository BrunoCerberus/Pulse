import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("ReadingHistoryViewModel Tests")
@MainActor
struct ReadingHistoryViewModelTests {
    let mockStorageService: MockStorageService
    let serviceLocator: ServiceLocator
    let sut: ReadingHistoryViewModel

    init() {
        mockStorageService = MockStorageService()
        serviceLocator = ServiceLocator()

        serviceLocator.register(StorageService.self, instance: mockStorageService)

        sut = ReadingHistoryViewModel(serviceLocator: serviceLocator)
    }

    @Test("Initial view state is correct")
    func initialViewState() {
        let state = sut.viewState
        #expect(state.articles.isEmpty)
        #expect(!state.isLoading)
        #expect(state.errorMessage == nil)
        // showEmptyState is true because bindings fire immediately with empty domain state
        #expect(state.showEmptyState)
    }

    @Test("Load history updates state")
    func loadHistory() async throws {
        mockStorageService.readArticles = Article.mockArticles

        sut.handle(event: .onAppear)

        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(!sut.viewState.articles.isEmpty)
    }

    @Test("Empty history shows empty state")
    func emptyHistory() async throws {
        mockStorageService.readArticles = []

        sut.handle(event: .onAppear)

        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(sut.viewState.showEmptyState)
    }

    @Test("Clear history removes all articles and shows empty state")
    func clearHistory() async throws {
        mockStorageService.readArticles = Article.mockArticles

        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(!sut.viewState.articles.isEmpty)
        #expect(!sut.viewState.showEmptyState)

        sut.handle(event: .onClearHistoryTapped)
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.viewState.articles.isEmpty)
        #expect(sut.viewState.showEmptyState)
    }

    @Test("Article tap sets selectedArticle")
    func articleTap() async throws {
        let article = Article.mockArticles[0]
        mockStorageService.readArticles = [article]

        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 300_000_000)

        sut.handle(event: .onArticleTapped(articleId: article.id))

        try await Task.sleep(nanoseconds: 50_000_000)

        #expect(sut.viewState.selectedArticle?.id == article.id)
    }

    @Test("Article navigated clears selectedArticle")
    func articleNavigated() async throws {
        let article = Article.mockArticles[0]
        mockStorageService.readArticles = [article]

        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 300_000_000)

        sut.handle(event: .onArticleTapped(articleId: article.id))
        try await Task.sleep(nanoseconds: 50_000_000)
        #expect(sut.viewState.selectedArticle != nil)

        sut.handle(event: .onArticleNavigated)
        try await Task.sleep(nanoseconds: 50_000_000)

        #expect(sut.viewState.selectedArticle == nil)
    }

    // MARK: - Loading State Tests

    @Test("Loading sets loading state")
    func loadingSetsLoadingState() async throws {
        var cancellables = Set<AnyCancellable>()
        var loadingStates: [Bool] = []

        sut.$viewState
            .map(\.isLoading)
            .sink { isLoading in
                loadingStates.append(isLoading)
            }
            .store(in: &cancellables)

        mockStorageService.readArticles = Article.mockArticles

        sut.handle(event: .onAppear)

        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(loadingStates.contains(true))
        #expect(loadingStates.last == false)
    }

    // MARK: - View State Transformation Tests

    @Test("Articles transformed to ArticleViewItems with isRead true")
    func articlesTransformedToViewItems() async throws {
        mockStorageService.readArticles = Article.mockArticles

        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(!sut.viewState.articles.isEmpty)
        let firstArticle = sut.viewState.articles[0]
        #expect(!firstArticle.id.isEmpty)
        #expect(!firstArticle.title.isEmpty)
        #expect(firstArticle.isRead == true)

        // All articles in reading history should have isRead = true
        for article in sut.viewState.articles {
            #expect(article.isRead == true)
        }
    }

    @Test("View state updates through publisher binding")
    func viewStateUpdatesThroughPublisher() async throws {
        var cancellables = Set<AnyCancellable>()
        var states: [ReadingHistoryViewState] = []

        sut.$viewState
            .sink { state in
                states.append(state)
            }
            .store(in: &cancellables)

        mockStorageService.readArticles = Article.mockArticles

        sut.handle(event: .onAppear)

        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(states.count > 1)
    }

    // MARK: - Empty State Tests

    @Test("Empty state shown after loading when no history")
    func emptyStateShownAfterLoading() async throws {
        mockStorageService.readArticles = []

        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(!sut.viewState.isLoading)
        #expect(sut.viewState.articles.isEmpty)
        #expect(sut.viewState.showEmptyState)
    }

    @Test("Empty state hidden when history exists")
    func emptyStateHiddenWhenHistoryExists() async throws {
        mockStorageService.readArticles = Article.mockArticles

        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(!sut.viewState.isLoading)
        #expect(!sut.viewState.articles.isEmpty)
        #expect(!sut.viewState.showEmptyState)
    }
}
