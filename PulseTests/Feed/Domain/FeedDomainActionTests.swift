import Foundation
@testable import Pulse
import Testing

@Suite("FeedDomainAction Lifecycle Tests")
struct FeedDomainActionLifecycleTests {
    @Test("Can create loadInitialData action")
    func loadInitialDataAction() {
        let action = FeedDomainAction.loadInitialData
        #expect(action == .loadInitialData)
    }
}

@Suite("FeedDomainAction Model Status Tests")
struct FeedDomainActionModelStatusTests {
    @Test("Can create modelStatusChanged action")
    func modelStatusChangedAction() {
        let status = LLMModelStatus.ready
        let action = FeedDomainAction.modelStatusChanged(status)
        #expect(action == .modelStatusChanged(status))
    }

    @Test("Different model statuses create different actions")
    func differentModelStatusesDifferentActions() {
        let action1 = FeedDomainAction.modelStatusChanged(.notLoaded)
        let action2 = FeedDomainAction.modelStatusChanged(.ready)
        #expect(action1 != action2)
    }

    @Test("modelStatusChanged with loading progress")
    func modelStatusChangedWithProgress() {
        let status = LLMModelStatus.loading(progress: 0.5)
        let action = FeedDomainAction.modelStatusChanged(status)
        #expect(action == .modelStatusChanged(status))
    }

    @Test("modelStatusChanged with error")
    func modelStatusChangedWithError() {
        let status = LLMModelStatus.error("Model load failed")
        let action = FeedDomainAction.modelStatusChanged(status)
        #expect(action == .modelStatusChanged(status))
    }
}

@Suite("FeedDomainAction Reading History Tests")
struct FeedDomainActionReadingHistoryTests {
    @Test("Can create readingHistoryLoaded action")
    func readingHistoryLoadedAction() {
        let articles = Article.mockArticles
        let action = FeedDomainAction.readingHistoryLoaded(articles)
        #expect(action == .readingHistoryLoaded(articles))
    }

    @Test("readingHistoryLoaded with empty array")
    func readingHistoryLoadedEmpty() {
        let action = FeedDomainAction.readingHistoryLoaded([])
        #expect(action == .readingHistoryLoaded([]))
    }

    @Test("readingHistoryLoaded with multiple articles")
    func readingHistoryLoadedMultiple() {
        let articles = Array(Article.mockArticles.prefix(5))
        let action = FeedDomainAction.readingHistoryLoaded(articles)
        #expect(action == .readingHistoryLoaded(articles))
    }

    @Test("Can create readingHistoryFailed action")
    func readingHistoryFailedAction() {
        let error = "Failed to load history"
        let action = FeedDomainAction.readingHistoryFailed(error)
        #expect(action == .readingHistoryFailed(error))
    }

    @Test("Different error messages create different actions")
    func differentErrorMessagesDifferentActions() {
        let action1 = FeedDomainAction.readingHistoryFailed("Error 1")
        let action2 = FeedDomainAction.readingHistoryFailed("Error 2")
        #expect(action1 != action2)
    }

    @Test("readingHistoryFailed with empty error message")
    func readingHistoryFailedEmptyMessage() {
        let action = FeedDomainAction.readingHistoryFailed("")
        #expect(action == .readingHistoryFailed(""))
    }
}

@Suite("FeedDomainAction Digest Generation Tests")
struct FeedDomainActionDigestGenerationTests {
    @Test("Can create generateDigest action")
    func generateDigestAction() {
        let action = FeedDomainAction.generateDigest
        #expect(action == .generateDigest)
    }

    @Test("Can create digestTokenReceived action")
    func digestTokenReceivedAction() {
        let token = "chunk of text"
        let action = FeedDomainAction.digestTokenReceived(token)
        #expect(action == .digestTokenReceived(token))
    }

    @Test("digestTokenReceived with empty token")
    func digestTokenReceivedEmpty() {
        let action = FeedDomainAction.digestTokenReceived("")
        #expect(action == .digestTokenReceived(""))
    }

    @Test("Multiple digestTokenReceived actions for streaming")
    func multipleDigestTokensStreaming() {
        let tokens = ["This ", "is ", "a ", "summary"]
        let actions = tokens.map { FeedDomainAction.digestTokenReceived($0) }

        #expect(actions.count == 4)
        #expect(actions[0] == .digestTokenReceived("This "))
        #expect(actions[3] == .digestTokenReceived("summary"))
    }

    @Test("Can create digestCompleted action")
    func digestCompletedAction() {
        let digest = DailyDigest.mockDigest
        let action = FeedDomainAction.digestCompleted(digest)
        #expect(action == .digestCompleted(digest))
    }

    @Test("Can create digestFailed action")
    func digestFailedAction() {
        let error = "Generation failed"
        let action = FeedDomainAction.digestFailed(error)
        #expect(action == .digestFailed(error))
    }

    @Test("Different error messages in digestFailed")
    func digestFailedDifferentErrors() {
        let action1 = FeedDomainAction.digestFailed("Error 1")
        let action2 = FeedDomainAction.digestFailed("Error 2")
        #expect(action1 != action2)
    }
}

@Suite("FeedDomainAction Navigation Tests")
struct FeedDomainActionNavigationTests {
    @Test("Can create selectArticle action")
    func selectArticleAction() {
        let article = Article.mockArticles[0]
        let action = FeedDomainAction.selectArticle(article)
        #expect(action == .selectArticle(article))
    }

    @Test("Different articles create different actions")
    func differentArticlesDifferentActions() {
        let action1 = FeedDomainAction.selectArticle(Article.mockArticles[0])
        let action2 = FeedDomainAction.selectArticle(Article.mockArticles[1])
        #expect(action1 != action2)
    }

    @Test("Can create clearSelectedArticle action")
    func clearSelectedArticleAction() {
        let action1 = FeedDomainAction.clearSelectedArticle
        let action2 = FeedDomainAction.clearSelectedArticle
        #expect(action1 == action2)
    }
}

@Suite("FeedDomainAction State Management Tests")
struct FeedDomainActionStateManagementTests {
    @Test("Can create generationStateChanged action")
    func generationStateChangedAction() {
        let state = FeedGenerationState.generating
        let action = FeedDomainAction.generationStateChanged(state)
        #expect(action == .generationStateChanged(state))
    }

    @Test("generationStateChanged with idle state")
    func generationStateChangedIdle() {
        let action = FeedDomainAction.generationStateChanged(.idle)
        #expect(action == .generationStateChanged(.idle))
    }

    @Test("generationStateChanged with error")
    func generationStateChangedError() {
        let state = FeedGenerationState.error("Failed")
        let action = FeedDomainAction.generationStateChanged(state)
        #expect(action == .generationStateChanged(state))
    }

    @Test("Can create clearError action")
    func clearErrorAction() {
        let action1 = FeedDomainAction.clearError
        let action2 = FeedDomainAction.clearError
        #expect(action1 == action2)
    }
}

@Suite("FeedDomainAction Equatable Tests")
struct FeedDomainActionEquatableTests {
    @Test("Same simple actions are equal")
    func sameSimpleActionsEqual() {
        let action1 = FeedDomainAction.loadInitialData
        let action2 = FeedDomainAction.loadInitialData
        #expect(action1 == action2)
    }

    @Test("Different simple actions not equal")
    func differentSimpleActionsNotEqual() {
        let action1 = FeedDomainAction.loadInitialData
        let action2 = FeedDomainAction.generateDigest
        #expect(action1 != action2)
    }

    @Test("Actions with different associated values not equal")
    func differentAssociatedValuesNotEqual() {
        let action1 = FeedDomainAction.digestFailed("Error 1")
        let action2 = FeedDomainAction.digestFailed("Error 2")
        #expect(action1 != action2)
    }
}

@Suite("FeedDomainAction Complex Digest Generation Workflow Tests")
struct FeedDomainActionComplexDigestWorkflowTests {
    @Test("Simulate full digest generation workflow")
    func fullDigestGenerationWorkflow() {
        let actions: [FeedDomainAction] = [
            .loadInitialData,
            .modelStatusChanged(.loading(progress: 0.0)),
            .modelStatusChanged(.loading(progress: 1.0)),
            .modelStatusChanged(.ready),
            .readingHistoryLoaded(Array(Article.mockArticles.prefix(5))),
            .generateDigest,
            .generationStateChanged(.generating),
            .digestTokenReceived("First "),
            .digestTokenReceived("chunk "),
            .digestTokenReceived("of text"),
            .digestCompleted(DailyDigest.mockDigest),
            .generationStateChanged(.completed),
        ]

        #expect(actions.count == 12)
        #expect(actions.first == .loadInitialData)
        #expect(actions.last == .generationStateChanged(.completed))
    }

    @Test("Simulate digest generation with error")
    func digestGenerationWithError() {
        let actions: [FeedDomainAction] = [
            .loadInitialData,
            .modelStatusChanged(.loading(progress: 0.5)),
            .modelStatusChanged(.error("Model load failed")),
            .generateDigest,
            .generationStateChanged(.generating),
            .digestFailed("Cannot generate without model"),
            .generationStateChanged(.error("Generation failed")),
            .clearError,
        ]

        #expect(actions.count == 8)
        #expect(actions[2] == .modelStatusChanged(.error("Model load failed")))
    }

    @Test("Simulate empty reading history")
    func emptyReadingHistory() {
        let actions: [FeedDomainAction] = [
            .loadInitialData,
            .readingHistoryLoaded([]),
            .clearError,
        ]

        #expect(actions[1] == .readingHistoryLoaded([]))
    }

    @Test("Simulate reading history load failure")
    func readingHistoryLoadFailure() {
        let actions: [FeedDomainAction] = [
            .loadInitialData,
            .readingHistoryFailed("Failed to fetch history"),
            .clearError,
        ]

        #expect(actions[1] == .readingHistoryFailed("Failed to fetch history"))
    }

    @Test("Simulate streaming digest generation")
    func streamingDigestGeneration() {
        let chunks = ["This ", "is ", "a ", "streamed ", "digest"]
        var actions: [FeedDomainAction] = [.generateDigest]

        for chunk in chunks {
            actions.append(.digestTokenReceived(chunk))
        }

        actions.append(.digestCompleted(DailyDigest.mockDigest))

        #expect(actions.count == 7)
        #expect(actions[1] == .digestTokenReceived("This "))
        #expect(actions[5] == .digestTokenReceived("digest"))
    }
}
