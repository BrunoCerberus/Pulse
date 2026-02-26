import Foundation
@testable import Pulse
import Testing

@Suite("ArticleDetailDomainState Tests")
struct ArticleDetailDomainStateTests {
    private static let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)

    private var testArticle: Article {
        Article(
            id: "test-article-1",
            title: "Test Article Title",
            description: "Test article description",
            content: "Full article content here...",
            author: "Test Author",
            source: ArticleSource(id: "test-source", name: "Test Source"),
            url: "https://example.com/article",
            imageURL: "https://example.com/image.jpg",
            publishedAt: Self.referenceDate,
            category: .technology
        )
    }

    // MARK: - Initial State Tests

    @Test("Initial state has correct values")
    func initialState() {
        let state = ArticleDetailDomainState.initial(article: testArticle)

        #expect(state.article.id == testArticle.id)
        #expect(state.isProcessingContent == true)
        #expect(state.processedContent == nil)
        #expect(state.processedDescription == nil)
        #expect(state.isBookmarked == false)
        #expect(state.showShareSheet == false)
        #expect(state.showSummarizationSheet == false)
        #expect(state.ttsPlaybackState == .idle)
        #expect(state.ttsProgress == 0.0)
        #expect(state.ttsSpeedPreset == .normal)
        #expect(state.isTTSPlayerVisible == false)
    }

    @Test("Initial state uses provided article")
    func initialStateUsesProvidedArticle() {
        let customArticle = Article(
            id: "custom-id",
            title: "Custom Title",
            source: ArticleSource(id: "source", name: "Source"),
            url: "https://example.com",
            publishedAt: Date()
        )

        let state = ArticleDetailDomainState.initial(article: customArticle)

        #expect(state.article.id == "custom-id")
        #expect(state.article.title == "Custom Title")
    }

    // MARK: - State Properties Tests

    @Test("State properties can be mutated")
    func statePropertiesMutability() {
        var state = ArticleDetailDomainState.initial(article: testArticle)

        // Test isProcessingContent
        state.isProcessingContent = false
        #expect(state.isProcessingContent == false)

        // Test isBookmarked
        state.isBookmarked = true
        #expect(state.isBookmarked == true)

        // Test showShareSheet
        state.showShareSheet = true
        #expect(state.showShareSheet == true)

        // Test showSummarizationSheet
        state.showSummarizationSheet = true
        #expect(state.showSummarizationSheet == true)
    }

    @Test("Processed content can be set")
    func processedContentCanBeSet() throws {
        var state = ArticleDetailDomainState.initial(article: testArticle)

        let attributedContent = try AttributedString(markdown: "**Bold** content")
        state.processedContent = attributedContent

        #expect(state.processedContent != nil)
        let contentString = state.processedContent.map { String($0.characters) } ?? ""
        #expect(contentString.contains("Bold"))
    }

    @Test("Processed description can be set")
    func processedDescriptionCanBeSet() throws {
        var state = ArticleDetailDomainState.initial(article: testArticle)

        let attributedDescription = try AttributedString(markdown: "*Italic* description")
        state.processedDescription = attributedDescription

        #expect(state.processedDescription != nil)
        let descString = state.processedDescription.map { String($0.characters) } ?? ""
        #expect(descString.contains("Italic"))
    }

    // MARK: - Equatable Tests

    @Test("States with same values are equal")
    func statesWithSameValuesAreEqual() {
        let state1 = ArticleDetailDomainState.initial(article: testArticle)
        var state2 = ArticleDetailDomainState.initial(article: testArticle)

        // Manually align all mutable properties
        state2.isProcessingContent = state1.isProcessingContent
        state2.isBookmarked = state1.isBookmarked
        state2.showShareSheet = state1.showShareSheet
        state2.showSummarizationSheet = state1.showSummarizationSheet

        #expect(state1 == state2)
    }

    @Test("States with different isProcessingContent are not equal")
    func statesWithDifferentProcessingContentAreNotEqual() {
        let state1 = ArticleDetailDomainState.initial(article: testArticle)
        var state2 = ArticleDetailDomainState.initial(article: testArticle)
        state2.isProcessingContent = false

        #expect(state1 != state2)
    }

    @Test("States with different isBookmarked are not equal")
    func statesWithDifferentBookmarkedAreNotEqual() {
        let state1 = ArticleDetailDomainState.initial(article: testArticle)
        var state2 = ArticleDetailDomainState.initial(article: testArticle)
        state2.isBookmarked = true

        #expect(state1 != state2)
    }

    @Test("States with different showShareSheet are not equal")
    func statesWithDifferentShowShareSheetAreNotEqual() {
        let state1 = ArticleDetailDomainState.initial(article: testArticle)
        var state2 = ArticleDetailDomainState.initial(article: testArticle)
        state2.showShareSheet = true

        #expect(state1 != state2)
    }

    @Test("States with different showSummarizationSheet are not equal")
    func statesWithDifferentShowSummarizationSheetAreNotEqual() {
        let state1 = ArticleDetailDomainState.initial(article: testArticle)
        var state2 = ArticleDetailDomainState.initial(article: testArticle)
        state2.showSummarizationSheet = true

        #expect(state1 != state2)
    }

    @Test("States with different articles are not equal")
    func statesWithDifferentArticlesAreNotEqual() {
        let state1 = ArticleDetailDomainState.initial(article: testArticle)
        let differentArticle = Article(
            id: "different-id",
            title: "Different Title",
            source: ArticleSource(id: "source", name: "Source"),
            url: "https://example.com",
            publishedAt: Date()
        )
        let state2 = ArticleDetailDomainState.initial(article: differentArticle)

        #expect(state1 != state2)
    }
}
