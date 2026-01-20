import Foundation
@testable import Pulse
import Testing

@Suite("SummarizationDomainAction User Control Tests")
struct SummarizationDomainActionUserControlTests {
    @Test("Can create startSummarization action")
    func startSummarizationAction() {
        let action1 = SummarizationDomainAction.startSummarization
        let action2 = SummarizationDomainAction.startSummarization
        #expect(action1 == action2)
    }

    @Test("Can create cancelSummarization action")
    func cancelSummarizationAction() {
        let action1 = SummarizationDomainAction.cancelSummarization
        let action2 = SummarizationDomainAction.cancelSummarization
        #expect(action1 == action2)
    }

    @Test("startSummarization and cancelSummarization are different")
    func startAndCancelDifferent() {
        let startAction = SummarizationDomainAction.startSummarization
        let cancelAction = SummarizationDomainAction.cancelSummarization
        #expect(startAction != cancelAction)
    }

    @Test("startSummarization is repeatable")
    func startSummarizationRepeatable() {
        let actions = Array(repeating: SummarizationDomainAction.startSummarization, count: 3)
        for action in actions {
            #expect(action == .startSummarization)
        }
    }
}

@Suite("SummarizationDomainAction State Management Tests")
struct SummarizationDomainActionStateManagementTests {
    @Test("Can create summarizationStateChanged action")
    func summarizationStateChangedAction() {
        let state = SummarizationState.generating
        let action = SummarizationDomainAction.summarizationStateChanged(state)
        #expect(action == .summarizationStateChanged(state))
    }

    @Test("summarizationStateChanged with idle state")
    func summarizationStateChangedIdle() {
        let action = SummarizationDomainAction.summarizationStateChanged(.idle)
        #expect(action == .summarizationStateChanged(.idle))
    }

    @Test("summarizationStateChanged with loadingModel state")
    func summarizationStateChangedLoading() {
        let state = SummarizationState.loadingModel(progress: 0.5)
        let action = SummarizationDomainAction.summarizationStateChanged(state)
        #expect(action == .summarizationStateChanged(state))
    }

    @Test("summarizationStateChanged with error state")
    func summarizationStateChangedError() {
        let state = SummarizationState.error("Summarization failed")
        let action = SummarizationDomainAction.summarizationStateChanged(state)
        #expect(action == .summarizationStateChanged(state))
    }

    @Test("summarizationStateChanged with completed state")
    func summarizationStateChangedCompleted() {
        let action = SummarizationDomainAction.summarizationStateChanged(.completed)
        #expect(action == .summarizationStateChanged(.completed))
    }

    @Test("Different summarization states create different actions")
    func differentSummarizationStatesDifferent() {
        let action1 = SummarizationDomainAction.summarizationStateChanged(.idle)
        let action2 = SummarizationDomainAction.summarizationStateChanged(.generating)
        #expect(action1 != action2)
    }
}

@Suite("SummarizationDomainAction Streaming Token Tests")
struct SummarizationDomainActionStreamingTokenTests {
    @Test("Can create summarizationTokenReceived action")
    func summarizationTokenReceivedAction() {
        let token = "chunk of text"
        let action = SummarizationDomainAction.summarizationTokenReceived(token)
        #expect(action == .summarizationTokenReceived(token))
    }

    @Test("summarizationTokenReceived with empty token")
    func summarizationTokenReceivedEmpty() {
        let action = SummarizationDomainAction.summarizationTokenReceived("")
        #expect(action == .summarizationTokenReceived(""))
    }

    @Test("Different tokens create different actions")
    func differentTokensDifferent() {
        let action1 = SummarizationDomainAction.summarizationTokenReceived("Token 1")
        let action2 = SummarizationDomainAction.summarizationTokenReceived("Token 2")
        #expect(action1 != action2)
    }

    @Test("Multiple summarizationTokenReceived actions for streaming")
    func multipleTokensStreaming() {
        let tokens = ["This ", "is ", "a ", "summary"]
        let actions = tokens.map { SummarizationDomainAction.summarizationTokenReceived($0) }

        #expect(actions.count == 4)
        #expect(actions[0] == .summarizationTokenReceived("This "))
        #expect(actions[3] == .summarizationTokenReceived("summary"))
    }
}

@Suite("SummarizationDomainAction Model Status Tests")
struct SummarizationDomainActionModelStatusTests {
    @Test("Can create modelStatusChanged action")
    func modelStatusChangedAction() {
        let status = LLMModelStatus.ready
        let action = SummarizationDomainAction.modelStatusChanged(status)
        #expect(action == .modelStatusChanged(status))
    }

    @Test("modelStatusChanged with notLoaded status")
    func modelStatusChangedNotLoaded() {
        let action = SummarizationDomainAction.modelStatusChanged(.notLoaded)
        #expect(action == .modelStatusChanged(.notLoaded))
    }

    @Test("modelStatusChanged with loading progress")
    func modelStatusChangedLoading() {
        let status = LLMModelStatus.loading(progress: 0.75)
        let action = SummarizationDomainAction.modelStatusChanged(status)
        #expect(action == .modelStatusChanged(status))
    }

    @Test("modelStatusChanged with error status")
    func modelStatusChangedError() {
        let status = LLMModelStatus.error("Model load failed")
        let action = SummarizationDomainAction.modelStatusChanged(status)
        #expect(action == .modelStatusChanged(status))
    }

    @Test("Different model statuses create different actions")
    func differentModelStatusesDifferent() {
        let action1 = SummarizationDomainAction.modelStatusChanged(.notLoaded)
        let action2 = SummarizationDomainAction.modelStatusChanged(.ready)
        #expect(action1 != action2)
    }
}

@Suite("SummarizationDomainAction Equatable Tests")
struct SummarizationDomainActionEquatableTests {
    @Test("Same simple actions are equal")
    func sameSimpleActionsEqual() {
        let action1 = SummarizationDomainAction.startSummarization
        let action2 = SummarizationDomainAction.startSummarization
        #expect(action1 == action2)
    }

    @Test("Different simple actions not equal")
    func differentSimpleActionsNotEqual() {
        let action1 = SummarizationDomainAction.startSummarization
        let action2 = SummarizationDomainAction.cancelSummarization
        #expect(action1 != action2)
    }

    @Test("Actions with different associated values not equal")
    func differentAssociatedValuesNotEqual() {
        let action1 = SummarizationDomainAction.summarizationTokenReceived("Token 1")
        let action2 = SummarizationDomainAction.summarizationTokenReceived("Token 2")
        #expect(action1 != action2)
    }
}

@Suite("SummarizationDomainAction Complex Summarization Workflow Tests")
struct SummarizationDomainActionComplexSummarizationWorkflowTests {
    @Test("Simulate start summarization")
    func testStartSummarization() {
        let actions: [SummarizationDomainAction] = [
            .startSummarization,
        ]
        #expect(actions.first == .startSummarization)
    }

    @Test("Simulate full summarization workflow")
    func fullSummarizationWorkflow() {
        let actions: [SummarizationDomainAction] = [
            .startSummarization,
            .modelStatusChanged(.loading(progress: 0.0)),
            .modelStatusChanged(.loading(progress: 1.0)),
            .modelStatusChanged(.ready),
            .summarizationStateChanged(.loadingModel(progress: 1.0)),
            .summarizationStateChanged(.generating),
            .summarizationTokenReceived("This "),
            .summarizationTokenReceived("is "),
            .summarizationTokenReceived("a "),
            .summarizationTokenReceived("summary"),
            .summarizationStateChanged(.completed),
        ]

        #expect(actions.count == 11)
        #expect(actions.first == .startSummarization)
        #expect(actions.last == .summarizationStateChanged(.completed))
    }

    @Test("Simulate summarization with error")
    func summarizationWithError() {
        let actions: [SummarizationDomainAction] = [
            .startSummarization,
            .modelStatusChanged(.loading(progress: 0.5)),
            .modelStatusChanged(.error("Model load failed")),
            .summarizationStateChanged(.error("Cannot generate without model")),
        ]

        #expect(actions.count == 4)
        #expect(actions[2] == .modelStatusChanged(.error("Model load failed")))
    }

    @Test("Simulate cancel summarization")
    func testCancelSummarization() {
        let actions: [SummarizationDomainAction] = [
            .startSummarization,
            .summarizationStateChanged(.generating),
            .cancelSummarization,
            .summarizationStateChanged(.idle),
        ]

        #expect(actions.count == 4)
        #expect(actions[2] == .cancelSummarization)
    }

    @Test("Simulate streaming summarization")
    func streamingSummarization() {
        let chunks = ["First ", "second ", "third ", "chunk"]
        var actions: [SummarizationDomainAction] = [
            .startSummarization,
            .modelStatusChanged(.ready),
            .summarizationStateChanged(.generating),
        ]

        for chunk in chunks {
            actions.append(.summarizationTokenReceived(chunk))
        }

        actions.append(.summarizationStateChanged(.completed))

        #expect(actions.count == 8)
        #expect(actions[3] == .summarizationTokenReceived("First "))
        #expect(actions.last == .summarizationStateChanged(.completed))
    }

    @Test("Simulate model loading with progress updates")
    func modelLoadingProgress() {
        var actions: [SummarizationDomainAction] = [.startSummarization]

        for progress in stride(from: 0.0, through: 1.0, by: 0.25) {
            actions.append(.modelStatusChanged(.loading(progress: progress)))
        }

        actions.append(.modelStatusChanged(.ready))

        #expect(actions.count == 6)
    }

    @Test("Simulate complete summarization lifecycle")
    func completeSummarizationLifecycle() {
        let actions: [SummarizationDomainAction] = [
            .startSummarization,
            .modelStatusChanged(.loading(progress: 0.0)),
            .modelStatusChanged(.ready),
            .summarizationStateChanged(.generating),
            .summarizationTokenReceived("Generated"),
            .summarizationTokenReceived(" summary"),
            .summarizationStateChanged(.completed),
        ]

        #expect(actions.count == 7)
        #expect(actions.first == .startSummarization)
        #expect(actions.last == .summarizationStateChanged(.completed))
    }
}
