import Foundation
@testable import Pulse
import Testing

@Suite("SummarizationDomainState Tests")
struct SummarizationDomainStateTests {
    // Use a fixed reference date to ensure consistent test results
    private static let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)

    private var testArticle: Article {
        Article(
            id: "article-1",
            title: "Test Article",
            source: ArticleSource(id: "source", name: "Source"),
            url: "https://example.com/article",
            publishedAt: Self.referenceDate,
            category: .technology
        )
    }

    @Test("Initial state has correct default values")
    func initialState() {
        let state = SummarizationDomainState.initial(article: testArticle)

        #expect(state.article.id == testArticle.id)
        #expect(state.summarizationState == .idle)
        #expect(state.generatedSummary == "")
        #expect(state.modelStatus == .notLoaded)
    }

    @Test("Summarization state can be changed")
    func summarizationStateCanBeChanged() {
        var state = SummarizationDomainState.initial(article: testArticle)

        state.summarizationState = .loadingModel(progress: 0.5)
        if case let .loadingModel(progress) = state.summarizationState {
            #expect(progress == 0.5)
        }

        state.summarizationState = .generating
        #expect(state.summarizationState == .generating)

        state.summarizationState = .completed
        #expect(state.summarizationState == .completed)

        state.summarizationState = .error("Failed")
        if case let .error(message) = state.summarizationState {
            #expect(message == "Failed")
        }
    }

    @Test("Generated summary can be set")
    func generatedSummaryCanBeSet() {
        var state = SummarizationDomainState.initial(article: testArticle)
        state.generatedSummary = "This is a summary."

        #expect(state.generatedSummary == "This is a summary.")
    }

    @Test("Model status can be changed")
    func modelStatusCanBeChanged() {
        var state = SummarizationDomainState.initial(article: testArticle)

        state.modelStatus = .ready
        #expect(state.modelStatus == .ready)

        state.modelStatus = .error("Load failed")
        #expect(state.modelStatus == .error("Load failed"))
    }

    @Test("Same states are equal")
    func sameStatesAreEqual() {
        let state1 = SummarizationDomainState.initial(article: testArticle)
        let state2 = SummarizationDomainState.initial(article: testArticle)

        #expect(state1 == state2)
    }

    @Test("States with different summarizationState are not equal")
    func differentSummarizationState() {
        let state1 = SummarizationDomainState.initial(article: testArticle)
        var state2 = SummarizationDomainState.initial(article: testArticle)
        state2.summarizationState = .generating

        #expect(state1 != state2)
    }

    @Test("States with different generatedSummary are not equal")
    func differentGeneratedSummary() {
        let state1 = SummarizationDomainState.initial(article: testArticle)
        var state2 = SummarizationDomainState.initial(article: testArticle)
        state2.generatedSummary = "Different summary"

        #expect(state1 != state2)
    }

    @Test("States with different articles are not equal")
    func differentArticles() {
        let article2 = Article(
            id: "article-2",
            title: "Different Article",
            source: ArticleSource(id: "source", name: "Source"),
            url: "https://example.com/other",
            publishedAt: Date()
        )

        let state1 = SummarizationDomainState.initial(article: testArticle)
        let state2 = SummarizationDomainState.initial(article: article2)

        #expect(state1 != state2)
    }
}

@Suite("SummarizationState Tests")
struct SummarizationStateTests {
    @Test("Idle state exists")
    func idle() {
        let state = SummarizationState.idle
        #expect(state == .idle)
    }

    @Test("LoadingModel state with progress")
    func loadingModel() {
        let state = SummarizationState.loadingModel(progress: 0.75)

        if case let .loadingModel(progress) = state {
            #expect(progress == 0.75)
        } else {
            Issue.record("Expected loadingModel state")
        }
    }

    @Test("Generating state exists")
    func generating() {
        let state = SummarizationState.generating
        #expect(state == .generating)
    }

    @Test("Completed state exists")
    func completed() {
        let state = SummarizationState.completed
        #expect(state == .completed)
    }

    @Test("Error state with message")
    func error() {
        let state = SummarizationState.error("Generation failed")

        if case let .error(message) = state {
            #expect(message == "Generation failed")
        } else {
            Issue.record("Expected error state")
        }
    }

    @Test("Same states are equal")
    func sameStatesAreEqual() {
        #expect(SummarizationState.idle == SummarizationState.idle)
        #expect(SummarizationState.generating == SummarizationState.generating)
        #expect(SummarizationState.completed == SummarizationState.completed)
        #expect(SummarizationState.loadingModel(progress: 0.5) == SummarizationState.loadingModel(progress: 0.5))
        #expect(SummarizationState.error("test") == SummarizationState.error("test"))
    }

    @Test("Different states are not equal")
    func differentStatesAreNotEqual() {
        #expect(SummarizationState.idle != SummarizationState.generating)
        #expect(SummarizationState.loadingModel(progress: 0.5) != SummarizationState.loadingModel(progress: 0.6))
        #expect(SummarizationState.error("a") != SummarizationState.error("b"))
    }
}
