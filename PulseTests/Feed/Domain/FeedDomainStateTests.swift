import Foundation
@testable import Pulse
import Testing

@Suite("FeedGenerationState Enum Tests")
struct FeedGenerationStateEnumTests {
    @Test("Can create idle state")
    func idleState() {
        let state = FeedGenerationState.idle
        #expect(state == .idle)
    }

    @Test("Can create loadingHistory state")
    func loadingHistoryState() {
        let state = FeedGenerationState.loadingHistory
        #expect(state == .loadingHistory)
    }

    @Test("Can create generating state")
    func generatingState() {
        let state = FeedGenerationState.generating
        #expect(state == .generating)
    }

    @Test("Can create completed state")
    func completedState() {
        let state = FeedGenerationState.completed
        #expect(state == .completed)
    }

    @Test("Can create error state with message")
    func errorStateWithMessage() {
        let message = "Failed to generate digest"
        let state = FeedGenerationState.error(message)
        #expect(state == .error(message))
    }

    @Test("Error states with different messages are not equal")
    func errorStatesNotEqual() {
        let state1 = FeedGenerationState.error("Error 1")
        let state2 = FeedGenerationState.error("Error 2")
        #expect(state1 != state2)
    }

    @Test("Non-error states are equatable")
    func nonErrorStatesEquatable() {
        let state1 = FeedGenerationState.idle
        let state2 = FeedGenerationState.idle
        #expect(state1 == state2)
    }

    @Test("Different non-error states are not equal")
    func differentNonErrorStatesNotEqual() {
        let state1 = FeedGenerationState.idle
        let state2 = FeedGenerationState.generating
        #expect(state1 != state2)
    }
}

@Suite("FeedDomainState Initialization Tests")
struct FeedDomainStateInitializationTests {
    @Test("Initial state is idle")
    func initialStateIdle() {
        let state = FeedDomainState()
        #expect(state.generationState == .idle)
    }

    @Test("Initial reading history is empty")
    func initialReadingHistoryEmpty() {
        let state = FeedDomainState()
        #expect(state.readingHistory.isEmpty)
    }

    @Test("Initial digest is nil")
    func initialDigestNil() {
        let state = FeedDomainState()
        #expect(state.currentDigest == nil)
    }

    @Test("Initial streaming text is empty")
    func initialStreamingTextEmpty() {
        let state = FeedDomainState()
        #expect(state.streamingText.isEmpty)
    }

    @Test("Initial model status is notLoaded")
    func initialModelStatusNotLoaded() {
        let state = FeedDomainState()
        #expect(state.modelStatus == .notLoaded)
    }

    @Test("Initial hasLoadedInitialData is false")
    func initialHasLoadedInitialDataFalse() {
        let state = FeedDomainState()
        #expect(!state.hasLoadedInitialData)
    }

    @Test("Initial selectedArticle is nil")
    func initialSelectedArticleNil() {
        let state = FeedDomainState()
        #expect(state.selectedArticle == nil)
    }
}

@Suite("FeedDomainState Generation State Transitions Tests")
struct FeedDomainStateGenerationStateTransitionsTests {
    @Test("Can transition from idle to loadingHistory")
    func idleToLoadingHistory() {
        var state = FeedDomainState()
        state.generationState = .loadingHistory
        #expect(state.generationState == .loadingHistory)
    }

    @Test("Can transition from loadingHistory to generating")
    func loadingHistoryToGenerating() {
        var state = FeedDomainState()
        state.generationState = .loadingHistory
        state.generationState = .generating
        #expect(state.generationState == .generating)
    }

    @Test("Can transition from generating to completed")
    func generatingToCompleted() {
        var state = FeedDomainState()
        state.generationState = .generating
        state.generationState = .completed
        #expect(state.generationState == .completed)
    }

    @Test("Can transition to error state")
    func transitionToError() {
        var state = FeedDomainState()
        state.generationState = .generating
        state.generationState = .error("Generation failed")
        #expect(state.generationState == .error("Generation failed"))
    }

    @Test("Can transition from error back to idle")
    func errorBackToIdle() {
        var state = FeedDomainState()
        state.generationState = .error("Failed")
        state.generationState = .idle
        #expect(state.generationState == .idle)
    }

    @Test("Full generation cycle")
    func fullGenerationCycle() {
        var state = FeedDomainState()
        #expect(state.generationState == .idle)

        state.generationState = .loadingHistory
        #expect(state.generationState == .loadingHistory)

        state.generationState = .generating
        #expect(state.generationState == .generating)

        state.generationState = .completed
        #expect(state.generationState == .completed)
    }
}

@Suite("FeedDomainState Reading History Tests")
struct FeedDomainStateReadingHistoryTests {
    @Test("Can set reading history articles")
    func setReadingHistory() {
        var state = FeedDomainState()
        let articles = Array(Article.mockArticles.prefix(3))
        state.readingHistory = articles
        #expect(state.readingHistory.count == 3)
    }

    @Test("Can append to reading history")
    func appendToReadingHistory() {
        var state = FeedDomainState()
        state.readingHistory = Array(Article.mockArticles.prefix(2))
        state.readingHistory.append(Article.mockArticles[2])
        #expect(state.readingHistory.count == 3)
    }

    @Test("Can clear reading history")
    func clearReadingHistory() {
        var state = FeedDomainState()
        state.readingHistory = Article.mockArticles
        state.readingHistory = []
        #expect(state.readingHistory.isEmpty)
    }

    @Test("hasRecentReadingHistory is true when history exists")
    func hasRecentReadingHistoryTrue() {
        var state = FeedDomainState()
        state.readingHistory = Array(Article.mockArticles.prefix(1))
        #expect(state.hasRecentReadingHistory)
    }

    @Test("hasRecentReadingHistory is false when history is empty")
    func hasRecentReadingHistoryFalse() {
        let state = FeedDomainState()
        #expect(!state.hasRecentReadingHistory)
    }
}

@Suite("FeedDomainState Current Digest Tests")
struct FeedDomainStateCurrentDigestTests {
    @Test("Can set current digest")
    func setCurrentDigest() {
        var state = FeedDomainState()
        let digest = DailyDigest(id: "test-digest", summary: "Test summary", sourceArticles: Article.mockArticles, generatedAt: Date())
        state.currentDigest = digest
        #expect(state.currentDigest == digest)
    }

    @Test("Can clear current digest")
    func clearCurrentDigest() {
        var state = FeedDomainState()
        state.currentDigest = DailyDigest(id: "digest", summary: "Summary", sourceArticles: [], generatedAt: Date())
        state.currentDigest = nil
        #expect(state.currentDigest == nil)
    }

    @Test("Setting new digest replaces old digest")
    func replaceDigest() {
        var state = FeedDomainState()
        state.currentDigest = DailyDigest(id: "digest", summary: "Summary", sourceArticles: [], generatedAt: Date())
        let newDigest = DailyDigest(id: "new-digest", summary: "New", sourceArticles: [], generatedAt: Date())
        state.currentDigest = newDigest
        #expect(state.currentDigest == newDigest)
    }
}

@Suite("FeedDomainState Streaming Text Tests")
struct FeedDomainStateStreamingTextTests {
    @Test("Can set streaming text")
    func setStreamingText() {
        var state = FeedDomainState()
        state.streamingText = "Loading..."
        #expect(state.streamingText == "Loading...")
    }

    @Test("Can append to streaming text")
    func appendToStreamingText() {
        var state = FeedDomainState()
        state.streamingText = "This is "
        state.streamingText += "the digest text."
        #expect(state.streamingText == "This is the digest text.")
    }

    @Test("Can clear streaming text")
    func clearStreamingText() {
        var state = FeedDomainState()
        state.streamingText = "Some text"
        state.streamingText = ""
        #expect(state.streamingText.isEmpty)
    }

    @Test("Streaming text with special characters")
    func streamingTextWithSpecialCharacters() {
        var state = FeedDomainState()
        state.streamingText = "Text with\nnewlines\tand\ttabs"
        #expect(state.streamingText.contains("\n"))
        #expect(state.streamingText.contains("\t"))
    }
}

@Suite("FeedDomainState Model Status Tests")
struct FeedDomainStateModelStatusTests {
    @Test("Can set model status to loading")
    func setModelStatusLoading() {
        var state = FeedDomainState()
        state.modelStatus = .loading(progress: 0.5)
        #expect(state.modelStatus == .loading(progress: 0.5))
    }

    @Test("Can set model status to ready")
    func setModelStatusReady() {
        var state = FeedDomainState()
        state.modelStatus = .ready
        #expect(state.modelStatus == .ready)
    }

    @Test("Can set model status to error")
    func setModelStatusError() {
        var state = FeedDomainState()
        state.modelStatus = .error("Model failed to load")
        #expect(state.modelStatus == .error("Model failed to load"))
    }

    @Test("Model status transitions from notLoaded to loading")
    func modelStatusNotLoadedToLoading() {
        var state = FeedDomainState()
        #expect(state.modelStatus == .notLoaded)
        state.modelStatus = .loading(progress: 0.0)
        #expect(state.modelStatus == .loading(progress: 0.0))
    }

    @Test("Model status transitions from loading to ready")
    func modelStatusLoadingToReady() {
        var state = FeedDomainState()
        state.modelStatus = .loading(progress: 1.0)
        state.modelStatus = .ready
        #expect(state.modelStatus == .ready)
    }
}

@Suite("FeedDomainState Data Loading Tracking Tests")
struct FeedDomainStateDataLoadingTrackingTests {
    @Test("Can set hasLoadedInitialData")
    func setHasLoadedInitialData() {
        var state = FeedDomainState()
        state.hasLoadedInitialData = true
        #expect(state.hasLoadedInitialData)
    }

    @Test("Initial data flag persists through state changes")
    func initialDataFlagPersists() {
        var state = FeedDomainState()
        state.hasLoadedInitialData = true
        state.generationState = .loadingHistory
        state.readingHistory = Article.mockArticles
        #expect(state.hasLoadedInitialData)
    }
}

@Suite("FeedDomainState Article Selection Tests")
struct FeedDomainStateArticleSelectionTests {
    @Test("Can set selected article")
    func setSelectedArticle() {
        var state = FeedDomainState()
        let article = Article.mockArticles[0]
        state.selectedArticle = article
        #expect(state.selectedArticle == article)
    }

    @Test("Can clear selected article")
    func clearSelectedArticle() {
        var state = FeedDomainState()
        state.selectedArticle = Article.mockArticles[0]
        state.selectedArticle = nil
        #expect(state.selectedArticle == nil)
    }
}

@Suite("FeedDomainState Equatable Tests")
struct FeedDomainStateEquatableTests {
    @Test("Two initial states are equal")
    func twoInitialStatesEqual() {
        let state1 = FeedDomainState()
        let state2 = FeedDomainState()
        #expect(state1 == state2)
    }

    @Test("States with different generation states are not equal")
    func differentGenerationStateNotEqual() {
        var state1 = FeedDomainState()
        var state2 = FeedDomainState()
        state1.generationState = .generating
        #expect(state1 != state2)
    }

    @Test("States with different reading history are not equal")
    func differentReadingHistoryNotEqual() {
        var state1 = FeedDomainState()
        var state2 = FeedDomainState()
        state1.readingHistory = Array(Article.mockArticles.prefix(1))
        #expect(state1 != state2)
    }

    @Test("States with different model status are not equal")
    func differentModelStatusNotEqual() {
        var state1 = FeedDomainState()
        var state2 = FeedDomainState()
        state1.modelStatus = .ready
        #expect(state1 != state2)
    }

    @Test("States become equal after same mutations")
    func statesEqualAfterSameMutations() {
        var state1 = FeedDomainState()
        var state2 = FeedDomainState()
        state1.generationState = .completed
        state2.generationState = .completed
        #expect(state1 == state2)
    }
}

@Suite("FeedDomainState Complex Digest Generation Scenarios")
struct FeedDomainStateComplexDigestScenarioTests {
    @Test("Simulate full digest generation workflow")
    func fullDigestGenerationWorkflow() {
        var state = FeedDomainState()
        #expect(state.generationState == .idle)

        // Load reading history
        state.generationState = .loadingHistory
        state.readingHistory = Array(Article.mockArticles.prefix(5))
        #expect(state.hasRecentReadingHistory)

        // Load model
        state.modelStatus = .loading(progress: 0.0)
        state.modelStatus = .loading(progress: 0.5)
        state.modelStatus = .ready

        // Generate digest
        state.generationState = .generating
        state.streamingText = "Here is a summary..."
        state.streamingText += " of your recent reading."

        // Complete
        state.generationState = .completed
        state.currentDigest = DailyDigest(id: "digest", summary: "Summary", sourceArticles: [], generatedAt: Date())
        state.hasLoadedInitialData = true

        #expect(state.generationState == .completed)
        #expect(state.currentDigest != nil)
        #expect(state.modelStatus == .ready)
    }

    @Test("Simulate digest generation with error")
    func digestGenerationWithError() {
        var state = FeedDomainState()
        state.generationState = .loadingHistory
        state.readingHistory = Array(Article.mockArticles.prefix(3))

        state.modelStatus = .loading(progress: 0.5)
        state.modelStatus = .error("Failed to load model")

        state.generationState = .error("Cannot generate without model")

        #expect(state.generationState == .error("Cannot generate without model"))
        #expect(state.modelStatus == .error("Failed to load model"))
    }

    @Test("Simulate digest regeneration")
    func digestRegeneration() {
        var state = FeedDomainState()

        // First generation
        state.generationState = .completed
        state.currentDigest = DailyDigest(id: "digest", summary: "Summary", sourceArticles: [], generatedAt: Date())
        state.streamingText = "First digest text"

        // Regenerate
        state.generationState = .idle
        state.streamingText = ""
        state.currentDigest = nil

        state.generationState = .loadingHistory
        state.generationState = .generating
        state.streamingText = "New digest text"
        state.generationState = .completed
        state.currentDigest = DailyDigest(id: "digest", summary: "Summary", sourceArticles: [], generatedAt: Date())

        #expect(state.streamingText == "New digest text")
        #expect(state.generationState == .completed)
    }

    @Test("Simulate reading history accumulation")
    func readingHistoryAccumulation() {
        var state = FeedDomainState()
        var articles: [Article] = []

        for (index, mockArticle) in Article.mockArticles.enumerated() {
            articles.append(mockArticle)
            state.readingHistory = articles
            #expect(state.readingHistory.count == index + 1)
        }
    }
}
