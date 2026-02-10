import Foundation
@testable import Pulse
import Testing

@Suite("SummarizationViewState Tests")
struct SummarizationViewStateTests {
    @Test("Initial state has correct defaults")
    func initialState() {
        let article = Article.mockArticles[0]
        let state = SummarizationViewState.initial(article: article)

        #expect(state.article == article)
        #expect(state.summarizationState == .idle)
        #expect(state.generatedSummary == "")
        #expect(state.modelStatus == .notLoaded)
    }

    @Test("Initial state preserves article reference")
    func preservesArticle() {
        let article = Article.mockArticles[0]
        let state = SummarizationViewState.initial(article: article)

        #expect(state.article.id == article.id)
        #expect(state.article.title == article.title)
    }

    @Test("SummarizationViewState is Equatable")
    func equatable() {
        let article = Article.mockArticles[0]
        let state1 = SummarizationViewState.initial(article: article)
        let state2 = SummarizationViewState.initial(article: article)

        #expect(state1 == state2)
    }

    @Test("Different articles produce different states")
    func differentArticles() {
        let article1 = Article.mockArticles[0]
        let article2 = Article.mockArticles[1]
        let state1 = SummarizationViewState.initial(article: article1)
        let state2 = SummarizationViewState.initial(article: article2)

        #expect(state1 != state2)
    }
}
