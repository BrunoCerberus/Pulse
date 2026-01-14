import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("ArticleDetailViewStateReducer Tests")
struct ArticleDetailViewStateReducerTests {
    let sut = ArticleDetailViewStateReducer()
    let testArticle = Article.mockArticles[0]

    @Test("Reducer maps article correctly")
    func mapsArticle() {
        let domainState = ArticleDetailDomainState.initial(article: testArticle)

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.article.id == testArticle.id)
        #expect(viewState.article.title == testArticle.title)
    }

    @Test("Reducer maps isProcessingContent correctly")
    func mapsIsProcessingContent() {
        var domainState = ArticleDetailDomainState.initial(article: testArticle)

        // Initial state has isProcessingContent = true
        var viewState = sut.reduce(domainState: domainState)
        #expect(viewState.isProcessingContent == true)

        // After processing completes
        domainState.isProcessingContent = false
        viewState = sut.reduce(domainState: domainState)
        #expect(viewState.isProcessingContent == false)
    }

    @Test("Reducer maps processedContent correctly")
    func mapsProcessedContent() {
        var domainState = ArticleDetailDomainState.initial(article: testArticle)

        // Initial state has nil content
        var viewState = sut.reduce(domainState: domainState)
        #expect(viewState.processedContent == nil)

        // After content is processed
        let testContent = AttributedString("Processed content")
        domainState.processedContent = testContent
        viewState = sut.reduce(domainState: domainState)
        #expect(viewState.processedContent == testContent)
    }

    @Test("Reducer maps processedDescription correctly")
    func mapsProcessedDescription() {
        var domainState = ArticleDetailDomainState.initial(article: testArticle)

        // Initial state has nil description
        var viewState = sut.reduce(domainState: domainState)
        #expect(viewState.processedDescription == nil)

        // After description is processed
        let testDescription = AttributedString("Processed description")
        domainState.processedDescription = testDescription
        viewState = sut.reduce(domainState: domainState)
        #expect(viewState.processedDescription == testDescription)
    }

    @Test("Reducer maps isBookmarked correctly")
    func mapsIsBookmarked() {
        var domainState = ArticleDetailDomainState.initial(article: testArticle)

        // Initial state is not bookmarked
        var viewState = sut.reduce(domainState: domainState)
        #expect(viewState.isBookmarked == false)

        // After bookmarking
        domainState.isBookmarked = true
        viewState = sut.reduce(domainState: domainState)
        #expect(viewState.isBookmarked == true)
    }

    @Test("Reducer maps showShareSheet correctly")
    func mapsShowShareSheet() {
        var domainState = ArticleDetailDomainState.initial(article: testArticle)

        // Initial state has share sheet hidden
        var viewState = sut.reduce(domainState: domainState)
        #expect(viewState.showShareSheet == false)

        // After showing share sheet
        domainState.showShareSheet = true
        viewState = sut.reduce(domainState: domainState)
        #expect(viewState.showShareSheet == true)
    }

    @Test("Reducer maps showSummarizationSheet correctly")
    func mapsShowSummarizationSheet() {
        var domainState = ArticleDetailDomainState.initial(article: testArticle)

        // Initial state has summarization sheet hidden
        var viewState = sut.reduce(domainState: domainState)
        #expect(viewState.showSummarizationSheet == false)

        // After showing summarization sheet
        domainState.showSummarizationSheet = true
        viewState = sut.reduce(domainState: domainState)
        #expect(viewState.showSummarizationSheet == true)
    }

    @Test("Reducer preserves all state in single transformation")
    func preservesAllState() {
        let testContent = AttributedString("Test content")
        let testDescription = AttributedString("Test description")

        let domainState = ArticleDetailDomainState(
            article: testArticle,
            isProcessingContent: false,
            processedContent: testContent,
            processedDescription: testDescription,
            isBookmarked: true,
            showShareSheet: true,
            showSummarizationSheet: false
        )

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.article.id == testArticle.id)
        #expect(viewState.isProcessingContent == false)
        #expect(viewState.processedContent == testContent)
        #expect(viewState.processedDescription == testDescription)
        #expect(viewState.isBookmarked == true)
        #expect(viewState.showShareSheet == true)
        #expect(viewState.showSummarizationSheet == false)
    }
}
