import Foundation
@testable import Pulse
import Testing

@Suite("SummarizationState Enum Tests")
struct SummarizationStateEnumTests {
    @Test("Can create idle state")
    func idleState() {
        let state = SummarizationState.idle
        #expect(state == .idle)
    }

    @Test("Can create loadingModel state with progress")
    func loadingModelState() {
        let state = SummarizationState.loadingModel(progress: 0.5)
        #expect(state == .loadingModel(progress: 0.5))
    }

    @Test("Can create generating state")
    func generatingState() {
        let state = SummarizationState.generating
        #expect(state == .generating)
    }

    @Test("Can create completed state")
    func completedState() {
        let state = SummarizationState.completed
        #expect(state == .completed)
    }

    @Test("Can create error state with message")
    func errorStateWithMessage() {
        let message = "Failed to summarize"
        let state = SummarizationState.error(message)
        #expect(state == .error(message))
    }

    @Test("Loading progress 0 is valid")
    func loadingProgressZero() {
        let state = SummarizationState.loadingModel(progress: 0.0)
        #expect(state == .loadingModel(progress: 0.0))
    }

    @Test("Loading progress 1.0 is valid")
    func loadingProgressOne() {
        let state = SummarizationState.loadingModel(progress: 1.0)
        #expect(state == .loadingModel(progress: 1.0))
    }

    @Test("Different progress values are not equal")
    func differentProgressNotEqual() {
        let state1 = SummarizationState.loadingModel(progress: 0.5)
        let state2 = SummarizationState.loadingModel(progress: 0.75)
        #expect(state1 != state2)
    }

    @Test("Error states with different messages are not equal")
    func errorStatesNotEqual() {
        let state1 = SummarizationState.error("Error 1")
        let state2 = SummarizationState.error("Error 2")
        #expect(state1 != state2)
    }

    @Test("Non-error states are equatable")
    func nonErrorStatesEquatable() {
        let state1 = SummarizationState.idle
        let state2 = SummarizationState.idle
        #expect(state1 == state2)
    }

    @Test("Different non-error states are not equal")
    func differentNonErrorStatesNotEqual() {
        let state1 = SummarizationState.idle
        let state2 = SummarizationState.generating
        #expect(state1 != state2)
    }
}

@Suite("SummarizationDomainState Initialization Tests")
struct SummarizationDomainStateInitializationTests {
    @Test("Can initialize with article using factory method")
    func initializeWithArticleFactory() {
        let article = Article.mockArticles[0]
        let state = SummarizationDomainState.initial(article: article)
        #expect(state.article == article)
    }

    @Test("Factory method sets article immutable")
    func articleIsImmutable() {
        let article = Article.mockArticles[0]
        let state = SummarizationDomainState.initial(article: article)
        #expect(state.article == article)
    }

    @Test("Initial summarization state is idle")
    func initialSummarizationStateIdle() {
        let article = Article.mockArticles[0]
        let state = SummarizationDomainState.initial(article: article)
        #expect(state.summarizationState == .idle)
    }

    @Test("Initial generated summary is empty")
    func initialGeneratedSummaryEmpty() {
        let article = Article.mockArticles[0]
        let state = SummarizationDomainState.initial(article: article)
        #expect(state.generatedSummary.isEmpty)
    }

    @Test("Initial model status is notLoaded")
    func initialModelStatusNotLoaded() {
        let article = Article.mockArticles[0]
        let state = SummarizationDomainState.initial(article: article)
        #expect(state.modelStatus == .notLoaded)
    }
}

@Suite("SummarizationDomainState Article Tests")
struct SummarizationDomainStateArticleTests {
    @Test("Article remains the same throughout state lifecycle")
    func articleConsistency() {
        let article = Article.mockArticles[0]
        var state = SummarizationDomainState.initial(article: article)
        let initialArticle = state.article

        state.summarizationState = .generating
        state.generatedSummary = "Summary text"
        state.modelStatus = .ready

        #expect(state.article == initialArticle)
        #expect(state.article == article)
    }

    @Test("Different articles create different states")
    func differentArticlesDifferentStates() {
        let article1 = Article.mockArticles[0]
        let article2 = Article.mockArticles[1]

        let state1 = SummarizationDomainState.initial(article: article1)
        let state2 = SummarizationDomainState.initial(article: article2)

        #expect(state1.article != state2.article)
    }
}

@Suite("SummarizationDomainState Summarization State Transitions Tests")
struct SummarizationDomainStateSummarizationStateTransitionsTests {
    @Test("Can transition from idle to loadingModel")
    func idleToLoadingModel() {
        let article = Article.mockArticles[0]
        var state = SummarizationDomainState.initial(article: article)
        state.summarizationState = .loadingModel(progress: 0.0)
        #expect(state.summarizationState == .loadingModel(progress: 0.0))
    }

    @Test("Can transition loadingModel progress from 0 to 1")
    func loadingModelProgress() {
        let article = Article.mockArticles[0]
        var state = SummarizationDomainState.initial(article: article)
        state.summarizationState = .loadingModel(progress: 0.25)
        state.summarizationState = .loadingModel(progress: 0.5)
        state.summarizationState = .loadingModel(progress: 0.75)
        state.summarizationState = .loadingModel(progress: 1.0)
        #expect(state.summarizationState == .loadingModel(progress: 1.0))
    }

    @Test("Can transition from loadingModel to generating")
    func loadingModelToGenerating() {
        let article = Article.mockArticles[0]
        var state = SummarizationDomainState.initial(article: article)
        state.summarizationState = .loadingModel(progress: 1.0)
        state.summarizationState = .generating
        #expect(state.summarizationState == .generating)
    }

    @Test("Can transition from generating to completed")
    func generatingToCompleted() {
        let article = Article.mockArticles[0]
        var state = SummarizationDomainState.initial(article: article)
        state.summarizationState = .generating
        state.summarizationState = .completed
        #expect(state.summarizationState == .completed)
    }

    @Test("Can transition to error state")
    func transitionToError() {
        let article = Article.mockArticles[0]
        var state = SummarizationDomainState.initial(article: article)
        state.summarizationState = .error("Summarization failed")
        #expect(state.summarizationState == .error("Summarization failed"))
    }

    @Test("Can transition from error back to idle")
    func errorBackToIdle() {
        let article = Article.mockArticles[0]
        var state = SummarizationDomainState.initial(article: article)
        state.summarizationState = .error("Failed")
        state.summarizationState = .idle
        #expect(state.summarizationState == .idle)
    }

    @Test("Full summarization cycle")
    func fullSummarizationCycle() {
        let article = Article.mockArticles[0]
        var state = SummarizationDomainState.initial(article: article)
        #expect(state.summarizationState == .idle)

        state.summarizationState = .loadingModel(progress: 0.0)
        state.summarizationState = .loadingModel(progress: 1.0)
        state.summarizationState = .generating
        state.summarizationState = .completed

        #expect(state.summarizationState == .completed)
    }
}

@Suite("SummarizationDomainState Generated Summary Tests")
struct SummarizationDomainStateGeneratedSummaryTests {
    @Test("Can set generated summary")
    func setGeneratedSummary() {
        let article = Article.mockArticles[0]
        var state = SummarizationDomainState.initial(article: article)
        let summary = "This is a summary of the article."
        state.generatedSummary = summary
        #expect(state.generatedSummary == summary)
    }

    @Test("Can append to generated summary")
    func appendToGeneratedSummary() {
        let article = Article.mockArticles[0]
        var state = SummarizationDomainState.initial(article: article)
        state.generatedSummary = "This is "
        state.generatedSummary += "a summary."
        #expect(state.generatedSummary == "This is a summary.")
    }

    @Test("Can clear generated summary")
    func clearGeneratedSummary() {
        let article = Article.mockArticles[0]
        var state = SummarizationDomainState.initial(article: article)
        state.generatedSummary = "Summary text"
        state.generatedSummary = ""
        #expect(state.generatedSummary.isEmpty)
    }

    @Test("Generated summary can be long")
    func generatedSummaryLong() {
        let article = Article.mockArticles[0]
        var state = SummarizationDomainState.initial(article: article)
        let longSummary = String(repeating: "word ", count: 100)
        state.generatedSummary = longSummary
        #expect(state.generatedSummary == longSummary)
    }

    @Test("Summary persists during state transitions")
    func summaryPersistsDuringStateTransitions() {
        let article = Article.mockArticles[0]
        var state = SummarizationDomainState.initial(article: article)
        state.generatedSummary = "Generated summary"
        state.summarizationState = .generating
        #expect(state.generatedSummary == "Generated summary")
    }
}

@Suite("SummarizationDomainState Model Status Tests")
struct SummarizationDomainStateModelStatusTests {
    @Test("Can set model status to loading")
    func setModelStatusLoading() {
        let article = Article.mockArticles[0]
        var state = SummarizationDomainState.initial(article: article)
        state.modelStatus = .loading(progress: 0.5)
        #expect(state.modelStatus == .loading(progress: 0.5))
    }

    @Test("Can set model status to ready")
    func setModelStatusReady() {
        let article = Article.mockArticles[0]
        var state = SummarizationDomainState.initial(article: article)
        state.modelStatus = .ready
        #expect(state.modelStatus == .ready)
    }

    @Test("Can set model status to error")
    func setModelStatusError() {
        let article = Article.mockArticles[0]
        var state = SummarizationDomainState.initial(article: article)
        state.modelStatus = .error("Model failed to load")
        #expect(state.modelStatus == .error("Model failed to load"))
    }

    @Test("Model status transitions from notLoaded to loading")
    func modelStatusNotLoadedToLoading() {
        let article = Article.mockArticles[0]
        var state = SummarizationDomainState.initial(article: article)
        #expect(state.modelStatus == .notLoaded)
        state.modelStatus = .loading(progress: 0.0)
        #expect(state.modelStatus == .loading(progress: 0.0))
    }

    @Test("Model status transitions from loading to ready")
    func modelStatusLoadingToReady() {
        let article = Article.mockArticles[0]
        var state = SummarizationDomainState.initial(article: article)
        state.modelStatus = .loading(progress: 1.0)
        state.modelStatus = .ready
        #expect(state.modelStatus == .ready)
    }

    @Test("Model status independent from summarization state")
    func modelStatusIndependentFromSummarizationState() {
        let article = Article.mockArticles[0]
        var state = SummarizationDomainState.initial(article: article)
        state.modelStatus = .ready
        state.summarizationState = .generating
        #expect(state.modelStatus == .ready)
        #expect(state.summarizationState == .generating)
    }
}

@Suite("SummarizationDomainState Equatable Tests")
struct SummarizationDomainStateEquatableTests {
    @Test("Two states with same article are equal")
    func twoStatesWithSameArticleEqual() {
        let article = Article.mockArticles[0]
        let state1 = SummarizationDomainState.initial(article: article)
        let state2 = SummarizationDomainState.initial(article: article)
        #expect(state1 == state2)
    }

    @Test("States with different articles are not equal")
    func differentArticlesNotEqual() {
        let article1 = Article.mockArticles[0]
        let article2 = Article.mockArticles[1]
        let state1 = SummarizationDomainState.initial(article: article1)
        let state2 = SummarizationDomainState.initial(article: article2)
        #expect(state1 != state2)
    }

    @Test("States with different summarization states are not equal")
    func differentSummarizationStateNotEqual() {
        let article = Article.mockArticles[0]
        var state1 = SummarizationDomainState.initial(article: article)
        var state2 = SummarizationDomainState.initial(article: article)
        state1.summarizationState = .generating
        #expect(state1 != state2)
    }

    @Test("States with different generated summary are not equal")
    func differentGeneratedSummaryNotEqual() {
        let article = Article.mockArticles[0]
        var state1 = SummarizationDomainState.initial(article: article)
        var state2 = SummarizationDomainState.initial(article: article)
        state1.generatedSummary = "Summary"
        #expect(state1 != state2)
    }

    @Test("States with different model status are not equal")
    func differentModelStatusNotEqual() {
        let article = Article.mockArticles[0]
        var state1 = SummarizationDomainState.initial(article: article)
        var state2 = SummarizationDomainState.initial(article: article)
        state1.modelStatus = .ready
        #expect(state1 != state2)
    }

    @Test("States become equal after same mutations")
    func statesEqualAfterSameMutations() {
        let article = Article.mockArticles[0]
        var state1 = SummarizationDomainState.initial(article: article)
        var state2 = SummarizationDomainState.initial(article: article)
        state1.summarizationState = .completed
        state2.summarizationState = .completed
        #expect(state1 == state2)
    }
}

@Suite("SummarizationDomainState Complex Summarization Scenarios")
struct SummarizationDomainStateComplexSummarizationScenarioTests {
    @Test("Simulate full summarization workflow")
    func fullSummarizationWorkflow() {
        let article = Article.mockArticles[0]
        var state = SummarizationDomainState.initial(article: article)
        #expect(state.summarizationState == .idle)

        // Load model
        state.modelStatus = .loading(progress: 0.0)
        state.modelStatus = .loading(progress: 0.5)
        state.modelStatus = .ready

        // Generate summary
        state.summarizationState = .generating
        state.generatedSummary = "Generated summary text of the article..."
        state.summarizationState = .completed

        #expect(state.summarizationState == .completed)
        #expect(!state.generatedSummary.isEmpty)
        #expect(state.modelStatus == .ready)
    }

    @Test("Simulate summarization with model error")
    func summarizationWithModelError() {
        let article = Article.mockArticles[0]
        var state = SummarizationDomainState.initial(article: article)

        state.modelStatus = .loading(progress: 0.5)
        state.modelStatus = .error("Failed to load model")

        state.summarizationState = .error("Cannot summarize without model")

        #expect(state.summarizationState == .error("Cannot summarize without model"))
        #expect(state.modelStatus == .error("Failed to load model"))
    }

    @Test("Simulate summarization retry after error")
    func summarizationRetryAfterError() {
        let article = Article.mockArticles[0]
        var state = SummarizationDomainState.initial(article: article)

        // First attempt fails
        state.summarizationState = .error("Failed")

        // Reset and retry
        state.summarizationState = .idle
        state.generatedSummary = ""
        state.modelStatus = .ready
        state.summarizationState = .generating
        state.generatedSummary = "Retry summary"
        state.summarizationState = .completed

        #expect(state.summarizationState == .completed)
        #expect(state.generatedSummary == "Retry summary")
    }

    @Test("Simulate streaming summary generation")
    func streamingSummaryGeneration() {
        let article = Article.mockArticles[0]
        var state = SummarizationDomainState.initial(article: article)

        state.modelStatus = .ready
        state.summarizationState = .generating

        // Simulate streaming updates
        state.generatedSummary = "This "
        state.generatedSummary += "is "
        state.generatedSummary += "a "
        state.generatedSummary += "summary"

        state.summarizationState = .completed

        #expect(state.generatedSummary == "This is a summary")
        #expect(state.summarizationState == .completed)
    }

    @Test("Simulate model loading with progress")
    func modelLoadingWithProgress() {
        let article = Article.mockArticles[0]
        var state = SummarizationDomainState.initial(article: article)

        for progress in stride(from: 0.0, through: 1.0, by: 0.1) {
            state.modelStatus = .loading(progress: progress)
            #expect(state.modelStatus == .loading(progress: progress))
        }

        state.modelStatus = .ready
        #expect(state.modelStatus == .ready)
    }

    @Test("Simulate complete summarization lifecycle")
    func completeRummarizationLifecycle() {
        let article = Article.mockArticles[0]
        var state = SummarizationDomainState.initial(article: article)

        // Initialize
        #expect(state.summarizationState == .idle)
        #expect(state.modelStatus == .notLoaded)

        // Load model
        state.modelStatus = .loading(progress: 0.0)
        state.modelStatus = .loading(progress: 1.0)
        state.modelStatus = .ready

        // Generate
        state.summarizationState = .generating
        state.generatedSummary = "Article summary"
        state.summarizationState = .completed

        // Verify final state
        #expect(state.article == article)
        #expect(state.summarizationState == .completed)
        #expect(state.generatedSummary == "Article summary")
        #expect(state.modelStatus == .ready)
    }
}
