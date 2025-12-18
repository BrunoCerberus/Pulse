import Combine
import Foundation
@testable import Pulse
import Testing

@Suite("HomeDomainInteractor Tests")
@MainActor
struct HomeDomainInteractorTests {
    let mockNewsService: MockNewsService
    let mockStorageService: MockStorageService
    let serviceLocator: ServiceLocator
    let sut: HomeDomainInteractor

    init() {
        mockNewsService = MockNewsService()
        mockStorageService = MockStorageService()
        serviceLocator = ServiceLocator()

        serviceLocator.register(NewsService.self, instance: mockNewsService)
        serviceLocator.register(StorageService.self, instance: mockStorageService)

        sut = HomeDomainInteractor(serviceLocator: serviceLocator)
    }

    @Test("Initial state is correct")
    func initialState() {
        let state = sut.currentState
        #expect(state.breakingNews.isEmpty)
        #expect(state.headlines.isEmpty)
        #expect(!state.isLoading)
        #expect(!state.isLoadingMore)
        #expect(state.error == nil)
        #expect(state.currentPage == 1)
        #expect(state.hasMorePages)
    }

    @Test("Load initial data updates state correctly")
    func testLoadInitialData() async throws {
        mockNewsService.topHeadlinesResult = .success(Article.mockArticles)
        mockNewsService.breakingNewsResult = .success(Array(Article.mockArticles.prefix(2)))

        var cancellables = Set<AnyCancellable>()
        var states: [HomeDomainState] = []

        sut.statePublisher
            .sink { state in
                states.append(state)
            }
            .store(in: &cancellables)

        sut.dispatch(action: .loadInitialData)

        try await Task.sleep(nanoseconds: 500_000_000)

        let finalState = sut.currentState
        #expect(!finalState.isLoading)
        #expect(finalState.error == nil)
    }

    @Test("Error handling works correctly")
    func errorHandling() async throws {
        let testError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        mockNewsService.topHeadlinesResult = .failure(testError)

        sut.dispatch(action: .loadInitialData)

        try await Task.sleep(nanoseconds: 500_000_000)

        let finalState = sut.currentState
        #expect(!finalState.isLoading)
        #expect(finalState.error != nil)
    }

    @Test("Refresh resets page and reloads data")
    func testRefresh() async throws {
        mockNewsService.topHeadlinesResult = .success(Article.mockArticles)
        mockNewsService.breakingNewsResult = .success(Array(Article.mockArticles.prefix(2)))

        sut.dispatch(action: .refresh)

        try await Task.sleep(nanoseconds: 500_000_000)

        let state = sut.currentState
        #expect(state.currentPage == 1)
        #expect(!state.isLoading)
        #expect(!state.breakingNews.isEmpty)
    }

    @Test("Select article saves to reading history")
    func testSelectArticle() async throws {
        let article = Article.mockArticles[0]

        sut.dispatch(action: .selectArticle(article))

        try await Task.sleep(nanoseconds: 100_000_000)

        let history = try await mockStorageService.fetchReadingHistory()
        #expect(history.contains(where: { $0.id == article.id }))
    }

    @Test("Bookmark article toggles bookmark status")
    func testBookmarkArticle() async throws {
        let article = Article.mockArticles[0]

        sut.dispatch(action: .bookmarkArticle(article))

        try await Task.sleep(nanoseconds: 100_000_000)

        let isBookmarked = await mockStorageService.isBookmarked(article.id)
        #expect(isBookmarked)
    }
}
