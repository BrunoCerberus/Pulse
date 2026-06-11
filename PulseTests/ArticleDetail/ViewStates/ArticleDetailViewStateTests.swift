import Foundation
@testable import Pulse
import Testing

@Suite("ArticleDetailViewState Tests")
struct ArticleDetailViewStateTests {
    @Test("Initial state has correct defaults")
    func initialState() {
        let article = Article.mockArticles[0]
        let state = ArticleDetailViewState.initial(article: article)

        #expect(state.article == article)
        #expect(state.isProcessingContent == true)
        #expect(state.processedContent == nil)
        #expect(state.processedDescription == nil)
        #expect(!state.isBookmarked)
        #expect(!state.showShareSheet)
        #expect(!state.showSummarizationSheet)
    }

    @Test("Initial state preserves article")
    func preservesArticle() {
        let article = Article.mockArticles[0]
        let state = ArticleDetailViewState.initial(article: article)

        #expect(state.article.id == article.id)
        #expect(state.article.title == article.title)
        #expect(state.article.url == article.url)
    }

    @Test("ArticleDetailViewState is Equatable")
    func equatable() {
        let article = Article.mockArticles[0]
        let state1 = ArticleDetailViewState.initial(article: article)
        let state2 = ArticleDetailViewState.initial(article: article)

        #expect(state1 == state2)
    }

    @Test("Different articles produce different states")
    func differentArticles() {
        let article1 = Article.mockArticles[0]
        let article2 = Article.mockArticles[1]
        let state1 = ArticleDetailViewState.initial(article: article1)
        let state2 = ArticleDetailViewState.initial(article: article2)

        #expect(state1 != state2)
    }

    @Test("Modified state is not equal to initial")
    func modifiedStateNotEqual() {
        let article = Article.mockArticles[0]
        var state = ArticleDetailViewState.initial(article: article)
        let initial = ArticleDetailViewState.initial(article: article)

        state.isBookmarked = true
        #expect(state != initial)

        state.isBookmarked = false
        state.showShareSheet = true
        #expect(state != initial)
    }
}
