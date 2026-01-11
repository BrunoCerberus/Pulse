import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("SummarizationViewModel Tests")
@MainActor
struct SummarizationViewModelTests {
    let mockSummarizationService: MockSummarizationService
    let serviceLocator: ServiceLocator
    let article: Article
    let sut: SummarizationViewModel

    init() {
        mockSummarizationService = MockSummarizationService()
        serviceLocator = ServiceLocator()
        article = Article.mockArticles[0]

        serviceLocator.register(SummarizationService.self, instance: mockSummarizationService)

        sut = SummarizationViewModel(article: article, serviceLocator: serviceLocator)
    }

    // MARK: - Initial State Tests

    @Test("Initial view state is correct")
    func initialViewState() {
        let state = sut.viewState

        #expect(state.article == article)
        #expect(state.summarizationState == .idle)
        #expect(state.generatedSummary == "")
        #expect(state.modelStatus == .notLoaded)
    }

    // MARK: - Event Handling Tests

    @Test("Handle onSummarizationStarted triggers summarization")
    func testOnSummarizationStarted() async throws {
        mockSummarizationService.loadDelay = 0.001
        mockSummarizationService.generateDelay = 0.001

        var cancellables = Set<AnyCancellable>()
        var states: [SummarizationViewState] = []

        sut.$viewState
            .sink { state in
                states.append(state)
            }
            .store(in: &cancellables)

        sut.handle(event: .onSummarizationStarted)

        // Wait for summarization to complete
        let completed = await waitForCondition(timeout: 1_000_000_000) { [sut] in
            sut.viewState.summarizationState == .completed
        }

        // Verify state changes occurred
        #expect(states.count > 1)
        #expect(completed, "Summarization should complete")
    }

    @Test("Handle onSummarizationCancelled resets state")
    func testOnSummarizationCancelled() async throws {
        mockSummarizationService.loadDelay = 1.0
        mockSummarizationService.generateDelay = 1.0

        // Start summarization
        sut.handle(event: .onSummarizationStarted)

        // Wait for it to start
        try await Task.sleep(nanoseconds: 50_000_000)

        // Cancel it
        sut.handle(event: .onSummarizationCancelled)

        // Wait for state to propagate
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(sut.viewState.summarizationState == .idle)
        #expect(sut.viewState.generatedSummary == "")
    }

    // MARK: - State Propagation Tests

    @Test("View state updates when summarization completes")
    func viewStateUpdatesOnCompletion() async throws {
        let expectedSummary = "This is a test summary"
        mockSummarizationService.generateResult = .success(expectedSummary)
        mockSummarizationService.loadDelay = 0.001
        mockSummarizationService.generateDelay = 0.001

        sut.handle(event: .onSummarizationStarted)

        // Wait for summarization to complete
        let completed = await waitForCondition(timeout: 1_000_000_000) { [sut] in
            sut.viewState.summarizationState == .completed
        }

        #expect(completed, "Summarization should complete")
        #expect(!sut.viewState.generatedSummary.isEmpty)
    }

    @Test("View state updates on error")
    func viewStateUpdatesOnError() async throws {
        let testError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        mockSummarizationService.generateResult = .failure(testError)
        mockSummarizationService.loadDelay = 0.001
        mockSummarizationService.generateDelay = 0.001

        sut.handle(event: .onSummarizationStarted)

        // Wait for error state
        let hasError = await waitForCondition(timeout: 1_000_000_000) { [sut] in
            if case .error = sut.viewState.summarizationState { return true }
            return false
        }

        #expect(hasError, "Expected error state")
    }

    // MARK: - View State Reducer Integration

    @Test("View state reducer correctly transforms domain state")
    func viewStateReducerIntegration() {
        let reducer = SummarizationViewStateReducer()

        let domainState = SummarizationDomainState(
            article: article,
            summarizationState: .generating,
            generatedSummary: "Partial summary...",
            modelStatus: .ready
        )

        let viewState = reducer.reduce(domainState: domainState)

        #expect(viewState.article == article)
        #expect(viewState.summarizationState == .generating)
        #expect(viewState.generatedSummary == "Partial summary...")
        #expect(viewState.modelStatus == .ready)
    }

    // MARK: - Article Preservation

    @Test("Article is preserved throughout summarization")
    func articleIsPreserved() async throws {
        mockSummarizationService.loadDelay = 0.01
        mockSummarizationService.generateDelay = 0.01

        // Initial state has the article
        #expect(sut.viewState.article == article)

        sut.handle(event: .onSummarizationStarted)

        try await Task.sleep(nanoseconds: 300_000_000)

        // Article is still present after summarization
        #expect(sut.viewState.article == article)
    }
}
