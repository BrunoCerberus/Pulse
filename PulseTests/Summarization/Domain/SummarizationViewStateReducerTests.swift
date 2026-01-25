import Foundation
@testable import Pulse
import Testing

@Suite("SummarizationViewStateReducer Tests")
struct SummarizationViewStateReducerTests {
    let sut = SummarizationViewStateReducer()

    /// Helper to create domain state with defaults
    private func makeDomainState(
        article: Article = Article.mockArticles[0],
        summarizationState: SummarizationState = .idle,
        generatedSummary: String = "",
        modelStatus: LLMModelStatus = .notLoaded
    ) -> SummarizationDomainState {
        SummarizationDomainState(
            article: article,
            summarizationState: summarizationState,
            generatedSummary: generatedSummary,
            modelStatus: modelStatus
        )
    }

    // MARK: - Basic Transformation Tests

    @Test("Reduce transforms all fields correctly")
    func reduceTransformsAllFieldsCorrectly() {
        let article = Article.mockArticles[0]
        let domainState = makeDomainState(
            article: article,
            summarizationState: .completed,
            generatedSummary: "Test summary",
            modelStatus: .ready
        )

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.article == article)
        #expect(viewState.summarizationState == .completed)
        #expect(viewState.generatedSummary == "Test summary")
        #expect(viewState.modelStatus == .ready)
    }

    // MARK: - Summarization State Tests

    @Test("Reduce passes through all summarization states correctly")
    func reducePassesThroughAllSummarizationStates() {
        let idleState = makeDomainState(summarizationState: .idle)
        let loadingState = makeDomainState(summarizationState: .loadingModel(progress: 0.5))
        let generatingState = makeDomainState(summarizationState: .generating)
        let completedState = makeDomainState(summarizationState: .completed)
        let errorState = makeDomainState(summarizationState: .error("Test error"))

        #expect(sut.reduce(domainState: idleState).summarizationState == .idle)
        #expect(sut.reduce(domainState: loadingState).summarizationState == .loadingModel(progress: 0.5))
        #expect(sut.reduce(domainState: generatingState).summarizationState == .generating)
        #expect(sut.reduce(domainState: completedState).summarizationState == .completed)
        #expect(sut.reduce(domainState: errorState).summarizationState == .error("Test error"))
    }

    // MARK: - Model Status Tests

    @Test("Reduce passes through all model statuses correctly")
    func reducePassesThroughAllModelStatuses() {
        let notLoadedState = makeDomainState(modelStatus: .notLoaded)
        let loadingState = makeDomainState(modelStatus: .loading(progress: 0.75))
        let readyState = makeDomainState(modelStatus: .ready)
        let errorState = makeDomainState(modelStatus: .error("Model error"))

        #expect(sut.reduce(domainState: notLoadedState).modelStatus == .notLoaded)
        #expect(sut.reduce(domainState: loadingState).modelStatus == .loading(progress: 0.75))
        #expect(sut.reduce(domainState: readyState).modelStatus == .ready)
        #expect(sut.reduce(domainState: errorState).modelStatus == .error("Model error"))
    }

    // MARK: - Generated Summary Tests

    @Test("Reduce passes through generated summary correctly")
    func reducePassesThroughGeneratedSummary() {
        let emptyState = makeDomainState(generatedSummary: "")
        let withSummaryState = makeDomainState(generatedSummary: "This is a detailed summary of the article.")

        #expect(sut.reduce(domainState: emptyState).generatedSummary == "")
        let expectedSummary = "This is a detailed summary of the article."
        #expect(sut.reduce(domainState: withSummaryState).generatedSummary == expectedSummary)
    }

    // MARK: - Initial State

    @Test("Initial domain state produces correct view state")
    func initialDomainStateProducesCorrectViewState() {
        let article = Article.mockArticles[0]
        let domainState = SummarizationDomainState.initial(article: article)

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.article == article)
        #expect(viewState.summarizationState == .idle)
        #expect(viewState.generatedSummary == "")
        #expect(viewState.modelStatus == .notLoaded)
    }
}
