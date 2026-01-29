import Foundation
@testable import Pulse
import Testing

@Suite("SummarizationDomainAction Tests")
struct SummarizationDomainActionTests {
    @Test("startSummarization action exists")
    func startSummarization() {
        let action = SummarizationDomainAction.startSummarization
        #expect(action == .startSummarization)
    }

    @Test("cancelSummarization action exists")
    func cancelSummarization() {
        let action = SummarizationDomainAction.cancelSummarization
        #expect(action == .cancelSummarization)
    }

    @Test("summarizationStateChanged with idle")
    func summarizationStateChangedIdle() {
        let action = SummarizationDomainAction.summarizationStateChanged(.idle)

        if case let .summarizationStateChanged(state) = action {
            #expect(state == .idle)
        } else {
            Issue.record("Expected summarizationStateChanged action")
        }
    }

    @Test("summarizationStateChanged with loadingModel")
    func summarizationStateChangedLoadingModel() {
        let action = SummarizationDomainAction.summarizationStateChanged(.loadingModel(progress: 0.5))

        if case let .summarizationStateChanged(state) = action {
            #expect(state == .loadingModel(progress: 0.5))
        } else {
            Issue.record("Expected summarizationStateChanged action")
        }
    }

    @Test("summarizationStateChanged with generating")
    func summarizationStateChangedGenerating() {
        let action = SummarizationDomainAction.summarizationStateChanged(.generating)

        if case let .summarizationStateChanged(state) = action {
            #expect(state == .generating)
        } else {
            Issue.record("Expected summarizationStateChanged action")
        }
    }

    @Test("summarizationStateChanged with completed")
    func summarizationStateChangedCompleted() {
        let action = SummarizationDomainAction.summarizationStateChanged(.completed)

        if case let .summarizationStateChanged(state) = action {
            #expect(state == .completed)
        } else {
            Issue.record("Expected summarizationStateChanged action")
        }
    }

    @Test("summarizationStateChanged with error")
    func summarizationStateChangedError() {
        let action = SummarizationDomainAction.summarizationStateChanged(.error("Failed"))

        if case let .summarizationStateChanged(state) = action {
            #expect(state == .error("Failed"))
        } else {
            Issue.record("Expected summarizationStateChanged action")
        }
    }

    @Test("summarizationTokenReceived with token")
    func summarizationTokenReceived() {
        let action = SummarizationDomainAction.summarizationTokenReceived("Hello")

        if case let .summarizationTokenReceived(token) = action {
            #expect(token == "Hello")
        } else {
            Issue.record("Expected summarizationTokenReceived action")
        }
    }

    @Test("modelStatusChanged with notLoaded")
    func modelStatusChangedNotLoaded() {
        let action = SummarizationDomainAction.modelStatusChanged(.notLoaded)

        if case let .modelStatusChanged(status) = action {
            #expect(status == .notLoaded)
        } else {
            Issue.record("Expected modelStatusChanged action")
        }
    }

    @Test("modelStatusChanged with ready")
    func modelStatusChangedReady() {
        let action = SummarizationDomainAction.modelStatusChanged(.ready)

        if case let .modelStatusChanged(status) = action {
            #expect(status == .ready)
        } else {
            Issue.record("Expected modelStatusChanged action")
        }
    }

    @Test("Same actions are equal")
    func sameActionsAreEqual() {
        #expect(
            SummarizationDomainAction.startSummarization ==
                SummarizationDomainAction.startSummarization
        )
        #expect(
            SummarizationDomainAction.cancelSummarization ==
                SummarizationDomainAction.cancelSummarization
        )
        #expect(
            SummarizationDomainAction.summarizationStateChanged(.idle) ==
                SummarizationDomainAction.summarizationStateChanged(.idle)
        )
        #expect(
            SummarizationDomainAction.summarizationTokenReceived("test") ==
                SummarizationDomainAction.summarizationTokenReceived("test")
        )
        #expect(
            SummarizationDomainAction.modelStatusChanged(.ready) ==
                SummarizationDomainAction.modelStatusChanged(.ready)
        )
    }

    @Test("Different actions are not equal")
    func differentActionsAreNotEqual() {
        #expect(
            SummarizationDomainAction.startSummarization !=
                SummarizationDomainAction.cancelSummarization
        )
        #expect(
            SummarizationDomainAction.summarizationTokenReceived("a") !=
                SummarizationDomainAction.summarizationTokenReceived("b")
        )
        #expect(
            SummarizationDomainAction.summarizationStateChanged(.idle) !=
                SummarizationDomainAction.summarizationStateChanged(.generating)
        )
        #expect(
            SummarizationDomainAction.modelStatusChanged(.notLoaded) !=
                SummarizationDomainAction.modelStatusChanged(.ready)
        )
    }
}
