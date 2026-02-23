import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("ReadingHistoryDomainInteractor Tests")
@MainActor
struct ReadingHistoryDomainInteractorTests {
    let mockStorageService: MockStorageService
    let serviceLocator: ServiceLocator

    init() {
        mockStorageService = MockStorageService()
        serviceLocator = ServiceLocator()
        serviceLocator.register(StorageService.self, instance: mockStorageService)
    }

    private func createSUT() -> ReadingHistoryDomainInteractor {
        ReadingHistoryDomainInteractor(serviceLocator: serviceLocator)
    }

    // MARK: - Initial State

    @Test("Initial state is correct")
    func initialState() {
        let sut = createSUT()
        let state = sut.currentState

        #expect(state.articles.isEmpty)
        #expect(!state.isLoading)
        #expect(state.error == nil)
        #expect(state.selectedArticle == nil)
    }

    // MARK: - Load History

    @Test("Load history fetches read articles")
    func loadHistory() async throws {
        let articles = Array(Article.mockArticles.prefix(3))
        mockStorageService.readArticles = articles

        let sut = createSUT()
        sut.dispatch(action: .loadHistory)

        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(sut.currentState.articles.count == 3)
        #expect(!sut.currentState.isLoading)
    }

    @Test("Load history shows empty state when no articles")
    func loadHistoryEmpty() async throws {
        mockStorageService.readArticles = []

        let sut = createSUT()
        sut.dispatch(action: .loadHistory)

        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(sut.currentState.articles.isEmpty)
        #expect(!sut.currentState.isLoading)
    }

    // MARK: - Clear History

    @Test("Clear history removes all articles")
    func clearHistory() async throws {
        let articles = Array(Article.mockArticles.prefix(2))
        mockStorageService.readArticles = articles

        let sut = createSUT()
        sut.dispatch(action: .loadHistory)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(sut.currentState.articles.count == 2)

        sut.dispatch(action: .clearHistory)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(sut.currentState.articles.isEmpty)
    }

    // MARK: - Article Selection

    @Test("Select article updates state")
    func selectArticle() async throws {
        let articles = Article.mockArticles
        mockStorageService.readArticles = articles

        let sut = createSUT()
        sut.dispatch(action: .loadHistory)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        let articleId = articles[0].id
        sut.dispatch(action: .selectArticle(articleId: articleId))

        #expect(sut.currentState.selectedArticle?.id == articleId)
    }

    @Test("Clear selected article resets selection")
    func clearSelectedArticle() async throws {
        let articles = Article.mockArticles
        mockStorageService.readArticles = articles

        let sut = createSUT()
        sut.dispatch(action: .loadHistory)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        sut.dispatch(action: .selectArticle(articleId: articles[0].id))
        #expect(sut.currentState.selectedArticle != nil)

        sut.dispatch(action: .clearSelectedArticle)
        #expect(sut.currentState.selectedArticle == nil)
    }
}
