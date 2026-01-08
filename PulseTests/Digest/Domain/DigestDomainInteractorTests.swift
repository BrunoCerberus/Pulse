import Combine
import Foundation
@testable import Pulse
import Testing

@Suite("DigestDomainInteractor Tests")
@MainActor
struct DigestDomainInteractorTests {
    let mockStorageService: MockStorageService
    let serviceLocator: ServiceLocator
    let sut: DigestDomainInteractor

    init() {
        mockStorageService = MockStorageService()
        serviceLocator = ServiceLocator()

        serviceLocator.register(StorageService.self, instance: mockStorageService)

        sut = DigestDomainInteractor(serviceLocator: serviceLocator)
    }

    // MARK: - Initial State Tests

    @Test("Initial state is correct")
    func initialState() {
        let state = sut.currentState
        #expect(state.summaries.isEmpty)
        #expect(!state.isLoading)
        #expect(state.error == nil)
    }

    // MARK: - Load Summaries Tests

    @Test("Load summaries fetches from storage")
    func loadSummariesFetchesFromStorage() async throws {
        let mockArticles = Article.mockArticles
        let summary1 = (article: mockArticles[0], summary: "Test summary 1", generatedAt: Date())
        let summary2 = (article: mockArticles[1], summary: "Test summary 2", generatedAt: Date())
        mockStorageService.summaries = [summary1, summary2]

        sut.dispatch(action: .loadSummaries)

        try await Task.sleep(nanoseconds: 300_000_000)

        let state = sut.currentState
        #expect(!state.isLoading)
        #expect(state.summaries.count == 2)
        #expect(state.error == nil)
    }

    @Test("Load summaries sets loading state")
    func loadSummariesSetsLoadingState() async throws {
        var cancellables = Set<AnyCancellable>()
        var loadingStates: [Bool] = []

        sut.statePublisher
            .map(\.isLoading)
            .sink { isLoading in
                loadingStates.append(isLoading)
            }
            .store(in: &cancellables)

        sut.dispatch(action: .loadSummaries)

        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(loadingStates.contains(true))
        #expect(loadingStates.last == false)
    }

    @Test("Load summaries with empty storage returns empty list")
    func loadSummariesWithEmptyStorageReturnsEmptyList() async throws {
        mockStorageService.summaries = []

        sut.dispatch(action: .loadSummaries)

        try await Task.sleep(nanoseconds: 300_000_000)

        let state = sut.currentState
        #expect(state.summaries.isEmpty)
        #expect(!state.isLoading)
        #expect(state.error == nil)
    }

    // MARK: - Delete Summary Tests

    @Test("Delete summary removes from state")
    func deleteSummaryRemovesFromState() async throws {
        let mockArticles = Article.mockArticles
        let summary1 = (article: mockArticles[0], summary: "Test summary 1", generatedAt: Date())
        let summary2 = (article: mockArticles[1], summary: "Test summary 2", generatedAt: Date())
        mockStorageService.summaries = [summary1, summary2]

        // Load first
        sut.dispatch(action: .loadSummaries)
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.currentState.summaries.count == 2)

        // Delete
        sut.dispatch(action: .deleteSummary(articleID: mockArticles[0].id))
        try await Task.sleep(nanoseconds: 300_000_000)

        let state = sut.currentState
        #expect(state.summaries.count == 1)
        #expect(!state.summaries.contains { $0.id == mockArticles[0].id })
    }

    @Test("Delete summary updates storage")
    func deleteSummaryUpdatesStorage() async throws {
        let mockArticles = Article.mockArticles
        let summary1 = (article: mockArticles[0], summary: "Test summary 1", generatedAt: Date())
        mockStorageService.summaries = [summary1]

        // Load first
        sut.dispatch(action: .loadSummaries)
        try await Task.sleep(nanoseconds: 300_000_000)

        // Delete
        sut.dispatch(action: .deleteSummary(articleID: mockArticles[0].id))
        try await Task.sleep(nanoseconds: 300_000_000)

        // Verify storage was updated
        #expect(mockStorageService.summaries.isEmpty)
    }

    // MARK: - Clear Error Tests

    @Test("Clear error removes error state")
    func clearErrorRemovesErrorState() async throws {
        // Manually set error state via the interactor's internal state
        // First trigger an action that might set error
        sut.dispatch(action: .loadSummaries)
        try await Task.sleep(nanoseconds: 300_000_000)

        // Clear error
        sut.dispatch(action: .clearError)

        #expect(sut.currentState.error == nil)
    }

    // MARK: - Summary Item Tests

    @Test("Summary items have correct properties")
    func summaryItemsHaveCorrectProperties() async throws {
        let mockArticle = Article.mockArticles[0]
        let summaryText = "This is a test summary"
        let generatedDate = Date()
        mockStorageService.summaries = [(article: mockArticle, summary: summaryText, generatedAt: generatedDate)]

        sut.dispatch(action: .loadSummaries)
        try await Task.sleep(nanoseconds: 300_000_000)

        let state = sut.currentState
        #expect(state.summaries.count == 1)

        let item = state.summaries[0]
        #expect(item.id == mockArticle.id)
        #expect(item.article.title == mockArticle.title)
        #expect(item.summary == summaryText)
        #expect(item.generatedAt == generatedDate)
    }

    // MARK: - State Publisher Tests

    @Test("State publisher emits updates")
    func statePublisherEmitsUpdates() async throws {
        var cancellables = Set<AnyCancellable>()
        var receivedStates: [DigestDomainState] = []

        sut.statePublisher
            .sink { state in
                receivedStates.append(state)
            }
            .store(in: &cancellables)

        mockStorageService.summaries = [(article: Article.mockArticles[0], summary: "Test", generatedAt: Date())]
        sut.dispatch(action: .loadSummaries)

        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(receivedStates.count > 1)
    }
}
