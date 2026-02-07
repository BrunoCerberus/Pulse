import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("LLMError Tests")
struct LLMErrorTests {
    @Test("all errors have errorDescription")
    func allErrorsHaveErrorDescription() {
        let errors: [LLMError] = [
            .modelNotLoaded,
            .modelLoadFailed("test"),
            .inferenceTimeout,
            .memoryPressure,
            .generationCancelled,
            .serviceUnavailable,
            .tokenizationFailed,
            .generationFailed("test"),
        ]
        for error in errors {
            let description = error.errorDescription
            #expect(description != nil)
        }
    }
}
