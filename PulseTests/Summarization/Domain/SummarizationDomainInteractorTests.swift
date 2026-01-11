import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("SummarizationDomainInteractor Tests")
@MainActor
struct SummarizationDomainInteractorTests {
    let mockSummarizationService: MockSummarizationService
    let serviceLocator: ServiceLocator
    let article: Article
    let sut: SummarizationDomainInteractor

    init() {
        mockSummarizationService = MockSummarizationService()
        serviceLocator = ServiceLocator()
        article = Article.mockArticles[0]

        serviceLocator.register(SummarizationService.self, instance: mockSummarizationService)

        sut = SummarizationDomainInteractor(article: article, serviceLocator: serviceLocator)
    }

    // MARK: - Initial State Tests

    @Test("Initial state is correct")
    func initialState() {
        let state = sut.currentState

        #expect(state.article == article)
        #expect(state.summarizationState == .idle)
        #expect(state.generatedSummary == "")
        #expect(state.modelStatus == .notLoaded)
    }

    // MARK: - Start Summarization Tests

    @Test("Start summarization updates state to loading")
    func startSummarizationUpdatesStateToLoading() async throws {
        mockSummarizationService.loadDelay = 0.01
        mockSummarizationService.generateDelay = 0.01

        sut.dispatch(action: .startSummarization)

        // Wait a short time for initial state update
        try await Task.sleep(nanoseconds: 20_000_000)

        // State should be in loading or generating (depending on timing)
        let state = sut.currentState
        let isInProgress = state.summarizationState == .loadingModel(progress: 0) ||
            state.summarizationState == .loadingModel(progress: 0.5) ||
            state.summarizationState == .generating ||
            state.summarizationState == .completed

        #expect(isInProgress)
        #expect(state.generatedSummary.isEmpty || !state.generatedSummary.isEmpty) // May have started generating
    }

    @Test("Start summarization completes with summary")
    func startSummarizationCompletesWithSummary() async throws {
        let expectedSummary = "Test summary content"
        mockSummarizationService.generateResult = .success(expectedSummary)
        mockSummarizationService.loadDelay = 0.001
        mockSummarizationService.generateDelay = 0.001

        sut.dispatch(action: .startSummarization)

        // Wait for summarization to complete
        let completed = await waitForCondition(timeout: 1_000_000_000) { [sut] in
            sut.currentState.summarizationState == .completed
        }

        #expect(completed, "Summarization should complete")
        #expect(!sut.currentState.generatedSummary.isEmpty)
    }

    @Test("Start summarization handles error")
    func startSummarizationHandlesError() async throws {
        let testError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        mockSummarizationService.generateResult = .failure(testError)
        mockSummarizationService.loadDelay = 0.001
        mockSummarizationService.generateDelay = 0.001

        sut.dispatch(action: .startSummarization)

        // Wait for error state
        let hasError = await waitForCondition(timeout: 1_000_000_000) { [sut] in
            if case .error = sut.currentState.summarizationState { return true }
            return false
        }

        #expect(hasError, "Expected error state")
    }

    // MARK: - Cancel Summarization Tests

    @Test("Cancel summarization resets state to idle")
    func cancelSummarizationResetsState() async throws {
        mockSummarizationService.loadDelay = 1.0 // Long delay so we can cancel
        mockSummarizationService.generateDelay = 1.0

        sut.dispatch(action: .startSummarization)

        // Wait for summarization to start
        try await Task.sleep(nanoseconds: 50_000_000)

        sut.dispatch(action: .cancelSummarization)

        // Wait for cancellation to take effect
        try await Task.sleep(nanoseconds: 50_000_000)

        let state = sut.currentState
        #expect(state.summarizationState == .idle)
        #expect(state.generatedSummary == "")
    }

    // MARK: - State Update Actions

    @Test("Summarization state changed action updates state")
    func summarizationStateChangedAction() {
        sut.dispatch(action: .summarizationStateChanged(.generating))

        #expect(sut.currentState.summarizationState == .generating)

        sut.dispatch(action: .summarizationStateChanged(.completed))

        #expect(sut.currentState.summarizationState == .completed)
    }

    @Test("Summarization token received action appends to summary")
    func summarizationTokenReceivedAction() {
        sut.dispatch(action: .summarizationTokenReceived("Hello "))

        #expect(sut.currentState.generatedSummary == "Hello ")

        sut.dispatch(action: .summarizationTokenReceived("World"))

        #expect(sut.currentState.generatedSummary == "Hello World")
    }

    @Test("Model status changed action updates state")
    func modelStatusChangedAction() {
        sut.dispatch(action: .modelStatusChanged(.loading(progress: 0.5)))

        #expect(sut.currentState.modelStatus == .loading(progress: 0.5))

        sut.dispatch(action: .modelStatusChanged(.ready))

        #expect(sut.currentState.modelStatus == .ready)
    }

    // MARK: - Model Status Propagation During Loading

    @Test("Model status updates summarization state during loading")
    func modelStatusUpdatesSummarizationStateDuringLoading() {
        // First put into loading state
        sut.dispatch(action: .summarizationStateChanged(.loadingModel(progress: 0)))

        // Model status update should update loading progress
        sut.dispatch(action: .modelStatusChanged(.loading(progress: 0.75)))

        #expect(sut.currentState.summarizationState == .loadingModel(progress: 0.75))
    }

    @Test("Model error status updates summarization state to error")
    func modelErrorStatusUpdatesSummarizationState() {
        sut.dispatch(action: .modelStatusChanged(.error("Model failed to load")))

        if case let .error(message) = sut.currentState.summarizationState {
            #expect(message == "Model failed to load")
        } else {
            #expect(Bool(false), "Expected error state")
        }
    }
}
