import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("LLMModelStatus Tests")
struct LLMModelStatusTests {
    @Test("all cases are equatable")
    func allCasesAreEquatable() {
        let status1: LLMModelStatus = .notLoaded
        let status2: LLMModelStatus = .notLoaded
        #expect(status1 == status2)
    }

    @Test("loading case stores progress")
    func loadingCaseStoresProgress() {
        let status: LLMModelStatus = .loading(progress: 0.5)
        if case let .loading(progress) = status {
            #expect(progress == 0.5)
        } else {
            Issue.record("Expected loading case")
        }
    }

    @Test("error case stores message")
    func errorCaseStoresMessage() {
        let status: LLMModelStatus = .error("Test error")
        if case let .error(message) = status {
            #expect(message == "Test error")
        } else {
            Issue.record("Expected error case")
        }
    }
}
