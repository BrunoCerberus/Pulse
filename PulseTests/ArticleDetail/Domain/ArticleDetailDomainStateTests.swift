import Foundation
@testable import Pulse
import Testing

@Suite("ArticleDetailDomainState Initialization Tests")
struct ArticleDetailDomainStateInitializationTests {
    @Test("Can initialize with article using factory method")
    func initializeWithArticleFactory() {
        let article = Article.mockArticles[0]
        let state = ArticleDetailDomainState.initial(article: article)
        #expect(state.article == article)
    }

    @Test("Factory method sets article immutable")
    func articleIsImmutable() {
        let article = Article.mockArticles[0]
        let state = ArticleDetailDomainState.initial(article: article)
        #expect(state.article == article)
    }

    @Test("Factory method sets isProcessingContent to true initially")
    func isProcessingContentTrue() {
        let article = Article.mockArticles[0]
        let state = ArticleDetailDomainState.initial(article: article)
        #expect(state.isProcessingContent)
    }

    @Test("Factory method sets processedContent to nil initially")
    func processedContentNilInitially() {
        let article = Article.mockArticles[0]
        let state = ArticleDetailDomainState.initial(article: article)
        #expect(state.processedContent == nil)
    }

    @Test("Factory method sets processedDescription to nil initially")
    func processedDescriptionNilInitially() {
        let article = Article.mockArticles[0]
        let state = ArticleDetailDomainState.initial(article: article)
        #expect(state.processedDescription == nil)
    }

    @Test("Factory method sets isBookmarked to false initially")
    func isBookmarkedFalse() {
        let article = Article.mockArticles[0]
        let state = ArticleDetailDomainState.initial(article: article)
        #expect(!state.isBookmarked)
    }

    @Test("Factory method sets showShareSheet to false initially")
    func showShareSheetFalse() {
        let article = Article.mockArticles[0]
        let state = ArticleDetailDomainState.initial(article: article)
        #expect(!state.showShareSheet)
    }

    @Test("Factory method sets showSummarizationSheet to false initially")
    func showSummarizationSheetFalse() {
        let article = Article.mockArticles[0]
        let state = ArticleDetailDomainState.initial(article: article)
        #expect(!state.showSummarizationSheet)
    }
}

@Suite("ArticleDetailDomainState Article Tests")
struct ArticleDetailDomainStateArticleTests {
    @Test("Article remains the same throughout state lifecycle")
    func articleConsistency() {
        let article = Article.mockArticles[0]
        var state = ArticleDetailDomainState.initial(article: article)
        let initialArticle = state.article

        state.isProcessingContent = false
        state.processedContent = AttributedString("content")
        state.isBookmarked = true

        #expect(state.article == initialArticle)
        #expect(state.article == article)
    }

    @Test("Different articles create different states")
    func differentArticlesDifferentStates() {
        let article1 = Article.mockArticles[0]
        let article2 = Article.mockArticles[1]

        let state1 = ArticleDetailDomainState.initial(article: article1)
        let state2 = ArticleDetailDomainState.initial(article: article2)

        #expect(state1.article != state2.article)
    }
}

@Suite("ArticleDetailDomainState Content Processing Tests")
struct ArticleDetailDomainStateContentProcessingTests {
    @Test("Can set isProcessingContent to false")
    func setIsProcessingContentFalse() {
        let article = Article.mockArticles[0]
        var state = ArticleDetailDomainState.initial(article: article)
        state.isProcessingContent = false
        #expect(!state.isProcessingContent)
    }

    @Test("Can set processedContent")
    func setProcessedContent() {
        let article = Article.mockArticles[0]
        var state = ArticleDetailDomainState.initial(article: article)
        let content = AttributedString("Article content here")
        state.processedContent = content
        #expect(state.processedContent == content)
    }

    @Test("Can clear processedContent")
    func clearProcessedContent() {
        let article = Article.mockArticles[0]
        var state = ArticleDetailDomainState.initial(article: article)
        state.processedContent = AttributedString("content")
        state.processedContent = nil
        #expect(state.processedContent == nil)
    }

    @Test("Can set processedDescription")
    func setProcessedDescription() {
        let article = Article.mockArticles[0]
        var state = ArticleDetailDomainState.initial(article: article)
        let description = AttributedString("Article description")
        state.processedDescription = description
        #expect(state.processedDescription == description)
    }

    @Test("Can clear processedDescription")
    func clearProcessedDescription() {
        let article = Article.mockArticles[0]
        var state = ArticleDetailDomainState.initial(article: article)
        state.processedDescription = AttributedString("description")
        state.processedDescription = nil
        #expect(state.processedDescription == nil)
    }

    @Test("Content and description are independent")
    func contentAndDescriptionIndependent() {
        let article = Article.mockArticles[0]
        var state = ArticleDetailDomainState.initial(article: article)

        state.processedContent = AttributedString("content")
        #expect(state.processedContent != nil)
        #expect(state.processedDescription == nil)

        state.processedDescription = AttributedString("description")
        #expect(state.processedContent != nil)
        #expect(state.processedDescription != nil)
    }

    @Test("Simulate content processing workflow")
    func contentProcessingWorkflow() {
        let article = Article.mockArticles[0]
        var state = ArticleDetailDomainState.initial(article: article)
        #expect(state.isProcessingContent)

        state.processedContent = AttributedString("Processed article content")
        state.processedDescription = AttributedString("Processed description")
        state.isProcessingContent = false

        #expect(!state.isProcessingContent)
        #expect(state.processedContent != nil)
        #expect(state.processedDescription != nil)
    }
}

@Suite("ArticleDetailDomainState Bookmark Tests")
struct ArticleDetailDomainStateBookmarkTests {
    @Test("Can set isBookmarked to true")
    func setIsBookmarkedTrue() {
        let article = Article.mockArticles[0]
        var state = ArticleDetailDomainState.initial(article: article)
        state.isBookmarked = true
        #expect(state.isBookmarked)
    }

    @Test("Can set isBookmarked to false")
    func setIsBookmarkedFalse() {
        let article = Article.mockArticles[0]
        var state = ArticleDetailDomainState.initial(article: article)
        state.isBookmarked = true
        state.isBookmarked = false
        #expect(!state.isBookmarked)
    }

    @Test("Can toggle bookmark flag")
    func toggleBookmarkFlag() {
        let article = Article.mockArticles[0]
        var state = ArticleDetailDomainState.initial(article: article)
        #expect(!state.isBookmarked)

        state.isBookmarked = true
        #expect(state.isBookmarked)

        state.isBookmarked = false
        #expect(!state.isBookmarked)
    }

    @Test("Bookmark flag independent from other properties")
    func bookmarkIndependentFromOtherProperties() {
        let article = Article.mockArticles[0]
        var state = ArticleDetailDomainState.initial(article: article)

        state.isProcessingContent = false
        state.isBookmarked = true
        state.showShareSheet = true

        #expect(!state.isProcessingContent)
        #expect(state.isBookmarked)
        #expect(state.showShareSheet)
    }
}

@Suite("ArticleDetailDomainState Share Sheet Tests")
struct ArticleDetailDomainStateShareSheetTests {
    @Test("Can show share sheet")
    func testShowShareSheet() {
        let article = Article.mockArticles[0]
        var state = ArticleDetailDomainState.initial(article: article)
        state.showShareSheet = true
        #expect(state.showShareSheet)
    }

    @Test("Can hide share sheet")
    func hideShareSheet() {
        let article = Article.mockArticles[0]
        var state = ArticleDetailDomainState.initial(article: article)
        state.showShareSheet = true
        state.showShareSheet = false
        #expect(!state.showShareSheet)
    }

    @Test("Can toggle share sheet visibility")
    func toggleShareSheetVisibility() {
        let article = Article.mockArticles[0]
        var state = ArticleDetailDomainState.initial(article: article)
        #expect(!state.showShareSheet)

        state.showShareSheet = true
        #expect(state.showShareSheet)

        state.showShareSheet = false
        #expect(!state.showShareSheet)
    }
}

@Suite("ArticleDetailDomainState Summarization Sheet Tests")
struct ArticleDetailDomainStateSummarizationSheetTests {
    @Test("Can show summarization sheet")
    func testShowSummarizationSheet() {
        let article = Article.mockArticles[0]
        var state = ArticleDetailDomainState.initial(article: article)
        state.showSummarizationSheet = true
        #expect(state.showSummarizationSheet)
    }

    @Test("Can hide summarization sheet")
    func hideSummarizationSheet() {
        let article = Article.mockArticles[0]
        var state = ArticleDetailDomainState.initial(article: article)
        state.showSummarizationSheet = true
        state.showSummarizationSheet = false
        #expect(!state.showSummarizationSheet)
    }

    @Test("Can toggle summarization sheet visibility")
    func toggleSummarizationSheetVisibility() {
        let article = Article.mockArticles[0]
        var state = ArticleDetailDomainState.initial(article: article)
        #expect(!state.showSummarizationSheet)

        state.showSummarizationSheet = true
        #expect(state.showSummarizationSheet)

        state.showSummarizationSheet = false
        #expect(!state.showSummarizationSheet)
    }

    @Test("Share and summarization sheets are independent")
    func shareAndSummarizationSheetsIndependent() {
        let article = Article.mockArticles[0]
        var state = ArticleDetailDomainState.initial(article: article)

        state.showShareSheet = true
        state.showSummarizationSheet = true
        #expect(state.showShareSheet)
        #expect(state.showSummarizationSheet)

        state.showShareSheet = false
        #expect(!state.showShareSheet)
        #expect(state.showSummarizationSheet)
    }
}

@Suite("ArticleDetailDomainState Equatable Tests")
struct ArticleDetailDomainStateEquatableTests {
    @Test("Two states with same article are equal")
    func twoStatesWithSameArticleEqual() {
        let article = Article.mockArticles[0]
        let state1 = ArticleDetailDomainState.initial(article: article)
        let state2 = ArticleDetailDomainState.initial(article: article)
        #expect(state1 == state2)
    }

    @Test("States with different articles are not equal")
    func differentArticlesNotEqual() {
        let article1 = Article.mockArticles[0]
        let article2 = Article.mockArticles[1]
        let state1 = ArticleDetailDomainState.initial(article: article1)
        let state2 = ArticleDetailDomainState.initial(article: article2)
        #expect(state1 != state2)
    }

    @Test("States with different processing flags are not equal")
    func differentProcessingFlagsNotEqual() {
        let article = Article.mockArticles[0]
        var state1 = ArticleDetailDomainState.initial(article: article)
        var state2 = ArticleDetailDomainState.initial(article: article)
        state1.isProcessingContent = false
        #expect(state1 != state2)
    }

    @Test("States with different bookmark flags are not equal")
    func differentBookmarkFlagsNotEqual() {
        let article = Article.mockArticles[0]
        var state1 = ArticleDetailDomainState.initial(article: article)
        var state2 = ArticleDetailDomainState.initial(article: article)
        state1.isBookmarked = true
        #expect(state1 != state2)
    }

    @Test("States with different sheet visibility are not equal")
    func differentSheetVisibilityNotEqual() {
        let article = Article.mockArticles[0]
        var state1 = ArticleDetailDomainState.initial(article: article)
        var state2 = ArticleDetailDomainState.initial(article: article)
        state1.showShareSheet = true
        #expect(state1 != state2)
    }

    @Test("States become equal after same mutations")
    func statesEqualAfterSameMutations() {
        let article = Article.mockArticles[0]
        var state1 = ArticleDetailDomainState.initial(article: article)
        var state2 = ArticleDetailDomainState.initial(article: article)

        state1.isProcessingContent = false
        state1.isBookmarked = true
        state2.isProcessingContent = false
        state2.isBookmarked = true

        #expect(state1 == state2)
    }
}

@Suite("ArticleDetailDomainState Complex Article Detail Scenarios")
struct ArticleDetailDomainStateComplexArticleScenarioTests {
    @Test("Simulate content loading workflow")
    func contentLoadingWorkflow() {
        let article = Article.mockArticles[0]
        var state = ArticleDetailDomainState.initial(article: article)
        #expect(state.isProcessingContent)

        state.processedContent = AttributedString("Article body text")
        state.processedDescription = AttributedString("Article description")
        state.isProcessingContent = false

        #expect(!state.isProcessingContent)
        #expect(state.processedContent != nil)
        #expect(state.processedDescription != nil)
    }

    @Test("Simulate bookmark toggle")
    func bookmarkToggle() {
        let article = Article.mockArticles[0]
        var state = ArticleDetailDomainState.initial(article: article)
        #expect(!state.isBookmarked)

        state.isBookmarked = true
        #expect(state.isBookmarked)

        state.isBookmarked = false
        #expect(!state.isBookmarked)
    }

    @Test("Simulate share sheet presentation")
    func shareSheetPresentation() {
        let article = Article.mockArticles[0]
        var state = ArticleDetailDomainState.initial(article: article)
        state.showShareSheet = true
        #expect(state.showShareSheet)

        state.showShareSheet = false
        #expect(!state.showShareSheet)
    }

    @Test("Simulate summarization sheet presentation")
    func summarizationSheetPresentation() {
        let article = Article.mockArticles[0]
        var state = ArticleDetailDomainState.initial(article: article)
        state.showSummarizationSheet = true
        #expect(state.showSummarizationSheet)

        state.showSummarizationSheet = false
        #expect(!state.showSummarizationSheet)
    }

    @Test("Simulate complete article detail flow")
    func completeArticleDetailFlow() {
        let article = Article.mockArticles[0]
        var state = ArticleDetailDomainState.initial(article: article)

        // Load content
        state.processedContent = AttributedString("Article content")
        state.processedDescription = AttributedString("Article description")
        state.isProcessingContent = false
        #expect(!state.isProcessingContent)

        // Bookmark article
        state.isBookmarked = true
        #expect(state.isBookmarked)

        // Share article
        state.showShareSheet = true
        #expect(state.showShareSheet)
        state.showShareSheet = false

        // Summarize article
        state.showSummarizationSheet = true
        #expect(state.showSummarizationSheet)
        state.showSummarizationSheet = false

        #expect(state.article == article)
        #expect(state.isBookmarked)
    }

    @Test("Simulate multiple sheet presentations")
    func multipleSheetPresentations() {
        let article = Article.mockArticles[0]
        var state = ArticleDetailDomainState.initial(article: article)

        state.showShareSheet = true
        #expect(state.showShareSheet)
        state.showShareSheet = false

        state.showSummarizationSheet = true
        #expect(state.showSummarizationSheet)
        state.showSummarizationSheet = false

        state.showShareSheet = true
        state.showSummarizationSheet = true
        #expect(state.showShareSheet && state.showSummarizationSheet)
    }
}
