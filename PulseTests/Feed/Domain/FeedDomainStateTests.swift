import Foundation
@testable import Pulse
import Testing

@Suite("FeedDomainState Tests")
struct FeedDomainStateTests {
    // Use a fixed reference date to ensure consistent test results
    private static let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)

    private var testArticles: [Article] {
        [
            Article(
                id: "article-1",
                title: "Article 1",
                source: ArticleSource(id: "source-1", name: "Source 1"),
                url: "https://example.com/1",
                publishedAt: Self.referenceDate,
                category: .technology
            ),
            Article(
                id: "article-2",
                title: "Article 2",
                source: ArticleSource(id: "source-2", name: "Source 2"),
                url: "https://example.com/2",
                publishedAt: Self.referenceDate.addingTimeInterval(-3600),
                category: .business
            ),
        ]
    }

    private var testDigest: DailyDigest {
        DailyDigest(
            id: "digest-1",
            summary: "Test summary content",
            sourceArticles: testArticles,
            generatedAt: Self.referenceDate
        )
    }

    // MARK: - Initial State Tests

    @Test("Initial state has correct default values")
    func initialState() {
        let state = FeedDomainState.initial

        #expect(state.generationState == .idle)
        #expect(state.readingHistory.isEmpty)
        #expect(state.currentDigest == nil)
        #expect(state.streamingText == "")
        #expect(state.modelStatus == .notLoaded)
        #expect(state.hasLoadedInitialData == false)
        #expect(state.selectedArticle == nil)
    }

    // MARK: - State Properties Tests

    @Test("Generation state can be changed")
    func generationStateCanBeChanged() {
        var state = FeedDomainState.initial

        state.generationState = .loadingHistory
        #expect(state.generationState == .loadingHistory)

        state.generationState = .generating
        #expect(state.generationState == .generating)

        state.generationState = .completed
        #expect(state.generationState == .completed)

        state.generationState = .error("Test error")
        if case let .error(message) = state.generationState {
            #expect(message == "Test error")
        }
    }

    @Test("Reading history can be set")
    func readingHistoryCanBeSet() {
        var state = FeedDomainState.initial
        state.readingHistory = testArticles

        #expect(state.readingHistory.count == 2)
        #expect(state.readingHistory[0].id == "article-1")
    }

    @Test("Current digest can be set")
    func currentDigestCanBeSet() {
        var state = FeedDomainState.initial
        state.currentDigest = testDigest

        #expect(state.currentDigest?.id == "digest-1")
        #expect(state.currentDigest?.summary == "Test summary content")
    }

    @Test("Streaming text can be updated")
    func streamingTextCanBeUpdated() {
        var state = FeedDomainState.initial
        state.streamingText = "Generated text"

        #expect(state.streamingText == "Generated text")
    }

    @Test("Model status can be changed")
    func modelStatusCanBeChanged() {
        var state = FeedDomainState.initial

        state.modelStatus = .loading(progress: 0.5)
        #expect(state.modelStatus == .loading(progress: 0.5))

        state.modelStatus = .ready
        #expect(state.modelStatus == .ready)

        state.modelStatus = .error("Load failed")
        #expect(state.modelStatus == .error("Load failed"))
    }

    @Test("Has loaded initial data can be set")
    func hasLoadedInitialDataCanBeSet() {
        var state = FeedDomainState.initial
        #expect(state.hasLoadedInitialData == false)

        state.hasLoadedInitialData = true
        #expect(state.hasLoadedInitialData == true)
    }

    @Test("Selected article can be set")
    func selectedArticleCanBeSet() {
        var state = FeedDomainState.initial
        state.selectedArticle = testArticles[0]

        #expect(state.selectedArticle?.id == "article-1")
    }

    // MARK: - Computed Properties Tests

    @Test("hasRecentReadingHistory returns false when empty")
    func hasRecentReadingHistoryFalseWhenEmpty() {
        let state = FeedDomainState.initial
        #expect(state.hasRecentReadingHistory == false)
    }

    @Test("hasRecentReadingHistory returns true when not empty")
    func hasRecentReadingHistoryTrueWhenNotEmpty() {
        var state = FeedDomainState.initial
        state.readingHistory = testArticles
        #expect(state.hasRecentReadingHistory == true)
    }

    @Test("digestDate returns formatted date from digest")
    func digestDateFromDigest() {
        var state = FeedDomainState.initial
        let fixedDate = Date(timeIntervalSince1970: 1_672_531_200)
        state.currentDigest = DailyDigest(
            id: "digest-1",
            summary: "Summary",
            sourceArticles: [],
            generatedAt: fixedDate
        )

        let dateString = state.digestDate
        #expect(!dateString.isEmpty)
    }

    @Test("digestDate returns today when no digest")
    func digestDateReturnsTodayWhenNoDigest() {
        let state = FeedDomainState.initial
        let dateString = state.digestDate
        #expect(!dateString.isEmpty)
    }

    // MARK: - Equatable Tests

    @Test("Same initial states are equal")
    func sameInitialStatesAreEqual() {
        let state1 = FeedDomainState.initial
        let state2 = FeedDomainState.initial

        #expect(state1 == state2)
    }

    @Test("States with different generationState are not equal")
    func statesWithDifferentGenerationState() {
        let state1 = FeedDomainState.initial
        var state2 = FeedDomainState.initial
        state2.generationState = .generating

        #expect(state1 != state2)
    }

    @Test("States with different readingHistory are not equal")
    func statesWithDifferentReadingHistory() {
        let state1 = FeedDomainState.initial
        var state2 = FeedDomainState.initial
        state2.readingHistory = testArticles

        #expect(state1 != state2)
    }

    @Test("States with different currentDigest are not equal")
    func statesWithDifferentCurrentDigest() {
        let state1 = FeedDomainState.initial
        var state2 = FeedDomainState.initial
        state2.currentDigest = testDigest

        #expect(state1 != state2)
    }

    @Test("States with different streamingText are not equal")
    func statesWithDifferentStreamingText() {
        let state1 = FeedDomainState.initial
        var state2 = FeedDomainState.initial
        state2.streamingText = "Some text"

        #expect(state1 != state2)
    }

    @Test("States with different modelStatus are not equal")
    func statesWithDifferentModelStatus() {
        let state1 = FeedDomainState.initial
        var state2 = FeedDomainState.initial
        state2.modelStatus = .ready

        #expect(state1 != state2)
    }

    @Test("States with different hasLoadedInitialData are not equal")
    func statesWithDifferentHasLoadedInitialData() {
        let state1 = FeedDomainState.initial
        var state2 = FeedDomainState.initial
        state2.hasLoadedInitialData = true

        #expect(state1 != state2)
    }

    @Test("States with different selectedArticle are not equal")
    func statesWithDifferentSelectedArticle() {
        let state1 = FeedDomainState.initial
        var state2 = FeedDomainState.initial
        state2.selectedArticle = testArticles[0]

        #expect(state1 != state2)
    }

    @Test("States with same values are equal")
    func statesWithSameValuesAreEqual() {
        var state1 = FeedDomainState.initial
        state1.readingHistory = testArticles
        state1.generationState = .completed
        state1.hasLoadedInitialData = true

        var state2 = FeedDomainState.initial
        state2.readingHistory = testArticles
        state2.generationState = .completed
        state2.hasLoadedInitialData = true

        #expect(state1 == state2)
    }
}

// MARK: - FeedGenerationState Tests

@Suite("FeedGenerationState Tests")
struct FeedGenerationStateTests {
    @Test("Idle state exists")
    func idleState() {
        let state = FeedGenerationState.idle
        #expect(state == .idle)
    }

    @Test("LoadingHistory state exists")
    func loadingHistoryState() {
        let state = FeedGenerationState.loadingHistory
        #expect(state == .loadingHistory)
    }

    @Test("Generating state exists")
    func generatingState() {
        let state = FeedGenerationState.generating
        #expect(state == .generating)
    }

    @Test("Completed state exists")
    func completedState() {
        let state = FeedGenerationState.completed
        #expect(state == .completed)
    }

    @Test("Error state with message")
    func errorState() {
        let state = FeedGenerationState.error("Something went wrong")

        if case let .error(message) = state {
            #expect(message == "Something went wrong")
        } else {
            Issue.record("Expected error state")
        }
    }

    @Test("Different states are not equal")
    func differentStatesAreNotEqual() {
        #expect(FeedGenerationState.idle != FeedGenerationState.loadingHistory)
        #expect(FeedGenerationState.loadingHistory != FeedGenerationState.generating)
        #expect(FeedGenerationState.generating != FeedGenerationState.completed)
        #expect(FeedGenerationState.completed != FeedGenerationState.error("test"))
    }

    @Test("Same states are equal")
    func sameStatesAreEqual() {
        #expect(FeedGenerationState.idle == FeedGenerationState.idle)
        #expect(FeedGenerationState.loadingHistory == FeedGenerationState.loadingHistory)
        #expect(FeedGenerationState.generating == FeedGenerationState.generating)
        #expect(FeedGenerationState.completed == FeedGenerationState.completed)
        #expect(FeedGenerationState.error("test") == FeedGenerationState.error("test"))
    }

    @Test("Error states with different messages are not equal")
    func errorStatesWithDifferentMessages() {
        #expect(FeedGenerationState.error("Error 1") != FeedGenerationState.error("Error 2"))
    }
}
