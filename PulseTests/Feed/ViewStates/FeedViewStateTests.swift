import Foundation
@testable import Pulse
import Testing

// MARK: - FeedViewState Tests

@Suite("FeedViewState Tests")
struct FeedViewStateTests {
    @Test("Initial state has correct defaults")
    func initialState() {
        let state = FeedViewState.initial

        #expect(state.displayState == .processing(phase: .generating))
        #expect(state.headerDate == "")
        #expect(state.streamingText == "")
        #expect(state.digest == nil)
        #expect(state.sourceArticles.isEmpty)
        #expect(state.errorMessage == nil)
        #expect(state.selectedArticle == nil)
    }

    @Test("FeedViewState is Equatable")
    func equatable() {
        let state1 = FeedViewState.initial
        let state2 = FeedViewState.initial

        #expect(state1 == state2)
    }
}

// MARK: - AIProcessingPhase Tests

@Suite("AIProcessingPhase Tests")
struct AIProcessingPhaseTests {
    @Test("Generating phase progress is 1.0")
    func generatingProgress() {
        let phase = AIProcessingPhase.generating
        #expect(phase.progress == 1.0)
    }

    @Test("Generating phase isGenerating is true")
    func generatingIsGenerating() {
        let phase = AIProcessingPhase.generating
        #expect(phase.isGenerating)
    }

    @Test("AIProcessingPhase is Equatable")
    func equatable() {
        #expect(AIProcessingPhase.generating == AIProcessingPhase.generating)
    }
}

// MARK: - FeedDisplayState Tests

@Suite("FeedDisplayState Tests")
struct FeedDisplayStateTests {
    @Test("All display states are distinct")
    func allStatesDistinct() {
        let states: [FeedDisplayState] = [
            .idle,
            .loading,
            .processing(phase: .generating),
            .completed,
            .empty,
            .error,
        ]

        for idx in 0 ..< states.count {
            for other in (idx + 1) ..< states.count {
                #expect(states[idx] != states[other])
            }
        }
    }

    @Test("FeedDisplayState is Equatable")
    func equatable() {
        #expect(FeedDisplayState.idle == FeedDisplayState.idle)
        #expect(FeedDisplayState.loading == FeedDisplayState.loading)
        #expect(FeedDisplayState.completed == FeedDisplayState.completed)
        #expect(FeedDisplayState.empty == FeedDisplayState.empty)
        #expect(FeedDisplayState.error == FeedDisplayState.error)
    }
}

// MARK: - DigestViewItem Tests

@Suite("DigestViewItem Tests")
struct DigestViewItemTests {
    @Test("DigestViewItem initializes from DailyDigest")
    func initFromDailyDigest() {
        let digest = DailyDigest(
            id: "digest-1",
            summary: "Test summary content",
            sourceArticles: Article.mockArticles,
            generatedAt: Date()
        )

        let viewItem = DigestViewItem(from: digest)

        #expect(viewItem.id == "digest-1")
        #expect(viewItem.summary == "Test summary content")
        #expect(viewItem.articleCount == Article.mockArticles.count)
    }

    @Test("DigestViewItem is Identifiable")
    func identifiable() {
        let digest = DailyDigest(
            id: "unique-id",
            summary: "Summary",
            sourceArticles: [],
            generatedAt: Date()
        )

        let viewItem = DigestViewItem(from: digest)
        #expect(viewItem.id == "unique-id")
    }
}

// MARK: - FeedSourceArticle Tests

@Suite("FeedSourceArticle Tests")
struct FeedSourceArticleTests {
    @Test("FeedSourceArticle initializes from Article")
    func initFromArticle() {
        let article = Article.mockArticles[0]

        let sourceArticle = FeedSourceArticle(from: article)

        #expect(sourceArticle.id == article.id)
        #expect(sourceArticle.title == article.title)
        #expect(sourceArticle.source == article.source.name)
        #expect(sourceArticle.article == article)
    }

    @Test("FeedSourceArticle maps category from Article")
    func mapsCategory() {
        let article = Article.mockArticles[0]

        let sourceArticle = FeedSourceArticle(from: article)

        #expect(sourceArticle.category == article.category?.displayName)
        #expect(sourceArticle.categoryType == article.category)
    }

    @Test("FeedSourceArticle is Identifiable")
    func identifiable() {
        let article = Article.mockArticles[0]
        let sourceArticle = FeedSourceArticle(from: article)

        #expect(sourceArticle.id == article.id)
    }

    @Test("FeedSourceArticle is Equatable")
    func equatable() {
        let article = Article.mockArticles[0]
        let source1 = FeedSourceArticle(from: article)
        let source2 = FeedSourceArticle(from: article)

        #expect(source1 == source2)
    }
}

// MARK: - DigestSection Tests

@Suite("DigestSection Tests")
struct DigestSectionTests {
    @Test("DigestSection default values")
    func defaultValues() {
        let section = DigestSection(
            title: "Technology",
            content: "Tech content"
        )

        #expect(section.title == "Technology")
        #expect(section.content == "Tech content")
        #expect(section.category == nil)
        #expect(section.relatedArticles.isEmpty)
        #expect(!section.isHighlight)
        #expect(!section.id.isEmpty)
    }

    @Test("DigestSection custom values")
    func customValues() {
        let article = FeedSourceArticle(from: Article.mockArticles[0])
        let section = DigestSection(
            id: "custom-id",
            title: "Business",
            content: "Business content",
            category: .business,
            relatedArticles: [article],
            isHighlight: true
        )

        #expect(section.id == "custom-id")
        #expect(section.category == .business)
        #expect(section.relatedArticles.count == 1)
        #expect(section.isHighlight)
    }

    @Test("DigestSection is Identifiable")
    func identifiable() {
        let section = DigestSection(
            id: "test-id",
            title: "Title",
            content: "Content"
        )

        #expect(section.id == "test-id")
    }

    @Test("DigestSection is Equatable")
    func equatable() {
        let section1 = DigestSection(
            id: "same-id",
            title: "Title",
            content: "Content"
        )
        let section2 = DigestSection(
            id: "same-id",
            title: "Title",
            content: "Content"
        )

        #expect(section1 == section2)
    }
}
