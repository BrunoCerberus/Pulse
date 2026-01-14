import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("FeedViewStateReducer Tests")
struct FeedViewStateReducerTests {
    let sut = FeedViewStateReducer()

    @Test("Idle state with empty history maps to empty display state")
    func idleEmptyHistory() {
        let domainState = FeedDomainState(
            generationState: .idle,
            readingHistory: [],
            currentDigest: nil,
            streamingText: "",
            modelStatus: .notLoaded,
            hasLoadedInitialData: true,
            selectedArticle: nil
        )

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.displayState == .empty)
        #expect(viewState.sourceArticles.isEmpty)
    }

    @Test("Idle state with history maps to idle display state")
    func idleWithHistory() {
        let domainState = FeedDomainState(
            generationState: .idle,
            readingHistory: Article.mockArticles,
            currentDigest: nil,
            streamingText: "",
            modelStatus: .notLoaded,
            hasLoadedInitialData: true,
            selectedArticle: nil
        )

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.displayState == .idle)
        #expect(viewState.sourceArticles.count == Article.mockArticles.count)
    }

    @Test("Loading history maps to loading display state")
    func loadingHistory() {
        let domainState = FeedDomainState(
            generationState: .loadingHistory,
            readingHistory: [],
            currentDigest: nil,
            streamingText: "",
            modelStatus: .notLoaded,
            hasLoadedInitialData: false,
            selectedArticle: nil
        )

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.displayState == .loading)
    }

    @Test("Generating maps to processing display state with generating phase")
    func generating() {
        let domainState = FeedDomainState(
            generationState: .generating,
            readingHistory: Article.mockArticles,
            currentDigest: nil,
            streamingText: "Generating text...",
            modelStatus: .ready,
            hasLoadedInitialData: true,
            selectedArticle: nil
        )

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.displayState == .processing(phase: .generating))
        #expect(viewState.streamingText == "Generating text...")
    }

    @Test("Completed maps to completed display state with digest")
    func completed() {
        let digest = DailyDigest(
            id: "1",
            summary: "Test summary",
            sourceArticles: Article.mockArticles,
            generatedAt: Date()
        )

        let domainState = FeedDomainState(
            generationState: .completed,
            readingHistory: Article.mockArticles,
            currentDigest: digest,
            streamingText: "",
            modelStatus: .ready,
            hasLoadedInitialData: true,
            selectedArticle: nil
        )

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.displayState == .completed)
        #expect(viewState.digest != nil)
        #expect(viewState.digest?.summary == "Test summary")
    }

    @Test("Error maps to error display state with message")
    func error() {
        let domainState = FeedDomainState(
            generationState: .error("Generation failed"),
            readingHistory: Article.mockArticles,
            currentDigest: nil,
            streamingText: "",
            modelStatus: .error("Model failed"),
            hasLoadedInitialData: true,
            selectedArticle: nil
        )

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.displayState == .error)
        #expect(viewState.errorMessage == "Generation failed")
    }

    @Test("Source articles are correctly mapped")
    func sourceArticlesMapping() {
        let articles = Article.mockArticles

        let domainState = FeedDomainState(
            generationState: .idle,
            readingHistory: articles,
            currentDigest: nil,
            streamingText: "",
            modelStatus: .notLoaded,
            hasLoadedInitialData: true,
            selectedArticle: nil
        )

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.sourceArticles.count == articles.count)

        let firstSource = viewState.sourceArticles.first
        let firstArticle = articles.first

        #expect(firstSource?.id == firstArticle?.id)
        #expect(firstSource?.title == firstArticle?.title)
        #expect(firstSource?.source == firstArticle?.source.name)
    }

    @Test("Header date is computed from current date when no digest")
    func headerDateComputed() {
        let domainState = FeedDomainState(
            generationState: .idle,
            readingHistory: [],
            currentDigest: nil,
            streamingText: "",
            modelStatus: .notLoaded,
            hasLoadedInitialData: true,
            selectedArticle: nil
        )

        let viewState = sut.reduce(domainState: domainState)

        // Header date should be computed (today's date), not empty
        #expect(!viewState.headerDate.isEmpty)
    }

    @Test("Selected article is passed through")
    func selectedArticlePassthrough() {
        let article = Article.mockArticles[0]

        let domainState = FeedDomainState(
            generationState: .idle,
            readingHistory: [],
            currentDigest: nil,
            streamingText: "",
            modelStatus: .notLoaded,
            hasLoadedInitialData: true,
            selectedArticle: article
        )

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.selectedArticle?.id == article.id)
    }
}
