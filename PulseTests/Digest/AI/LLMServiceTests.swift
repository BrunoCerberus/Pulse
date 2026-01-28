import Foundation
@testable import Pulse
import Testing

// MARK: - LLMInferenceConfig Tests

@Suite("LLMInferenceConfig Tests")
struct LLMInferenceConfigTests {
    @Test("LLMInferenceConfig initializes with all properties")
    func initializesWithAllProperties() {
        let config = LLMInferenceConfig(
            maxTokens: 512,
            temperature: 0.5,
            topP: 0.8,
            stopSequences: ["STOP", "END"]
        )

        #expect(config.maxTokens == 512)
        #expect(config.temperature == 0.5)
        #expect(config.topP == 0.8)
        #expect(config.stopSequences == ["STOP", "END"])
    }

    @Test("LLMInferenceConfig default returns correct values")
    func defaultConfigReturnsCorrectValues() {
        let defaultConfig = LLMInferenceConfig.default

        #expect(defaultConfig.maxTokens == 1024)
        #expect(defaultConfig.temperature == 0.7)
        #expect(defaultConfig.topP == 0.9)
        #expect(defaultConfig.stopSequences == ["</digest>", "\n\n\n"])
    }

    @Test("LLMInferenceConfig default is same across multiple calls")
    func defaultConfigIsConsistent() {
        let config1 = LLMInferenceConfig.default
        let config2 = LLMInferenceConfig.default

        #expect(config1 == config2)
    }

    @Test("LLMInferenceConfig Equatable conformance works correctly")
    func equatableConformance() {
        let config1 = LLMInferenceConfig(
            maxTokens: 1024,
            temperature: 0.7,
            topP: 0.9,
            stopSequences: ["</digest>"]
        )

        let config2 = LLMInferenceConfig(
            maxTokens: 1024,
            temperature: 0.7,
            topP: 0.9,
            stopSequences: ["</digest>"]
        )

        let config3 = LLMInferenceConfig(
            maxTokens: 512,
            temperature: 0.5,
            topP: 0.8,
            stopSequences: ["STOP"]
        )

        #expect(config1 == config2)
        #expect(config1 != config3)
        #expect(config2 != config3)
    }

    @Test("LLMInferenceConfig equality checks all properties")
    func equalityChecksAllProperties() {
        let baseConfig = LLMInferenceConfig.default

        let differentMaxTokens = LLMInferenceConfig(
            maxTokens: 2048,
            temperature: baseConfig.temperature,
            topP: baseConfig.topP,
            stopSequences: baseConfig.stopSequences
        )
        #expect(baseConfig != differentMaxTokens)

        let differentTemperature = LLMInferenceConfig(
            maxTokens: baseConfig.maxTokens,
            temperature: 0.5,
            topP: baseConfig.topP,
            stopSequences: baseConfig.stopSequences
        )
        #expect(baseConfig != differentTemperature)

        let differentTopP = LLMInferenceConfig(
            maxTokens: baseConfig.maxTokens,
            temperature: baseConfig.temperature,
            topP: 0.5,
            stopSequences: baseConfig.stopSequences
        )
        #expect(baseConfig != differentTopP)

        let differentStopSequences = LLMInferenceConfig(
            maxTokens: baseConfig.maxTokens,
            temperature: baseConfig.temperature,
            topP: baseConfig.topP,
            stopSequences: ["EOF"]
        )
        #expect(baseConfig != differentStopSequences)
    }
}

// MARK: - LLMModelStatus Tests

@Suite("LLMModelStatus Tests")
struct LLMModelStatusTests {
    @Test("LLMModelStatus has all cases")
    func hasAllCases() {
        let allCases: [LLMModelStatus] = [
            .notLoaded,
            .loading(progress: 0.5),
            .ready,
            .error("test error"),
        ]
        #expect(allCases.count == 4)
    }

    @Test("LLMModelStatus notLoaded case exists")
    func notLoadedCaseExists() {
        let status: LLMModelStatus = .notLoaded
        switch status {
        case .notLoaded:
            #expect(true)
        default:
            Issue.record("Should be notLoaded case")
        }
    }

    @Test("LLMModelStatus ready case exists")
    func readyCaseExists() {
        let status: LLMModelStatus = .ready
        switch status {
        case .ready:
            #expect(true)
        default:
            Issue.record("Should be ready case")
        }
    }

    @Test("LLMModelStatus loading case stores progress value")
    func loadingCaseStoresProgress() {
        let status: LLMModelStatus = .loading(progress: 0.75)
        switch status {
        case let .loading(progress):
            #expect(progress == 0.75)
        default:
            Issue.record("Should be loading case")
        }
    }

    @Test("LLMModelStatus error case stores message")
    func errorCaseStoresMessage() {
        let status: LLMModelStatus = .error("memory issue")
        switch status {
        case let .error(message):
            #expect(message == "memory issue")
        default:
            Issue.record("Should be error case")
        }
    }

    @Test("LLMModelStatus Equatable conformance works for simple cases")
    func equatableForSimpleCases() {
        #expect(LLMModelStatus.notLoaded == LLMModelStatus.notLoaded)
        #expect(LLMModelStatus.ready == LLMModelStatus.ready)
        #expect(LLMModelStatus.notLoaded != LLMModelStatus.ready)
    }

    @Test("LLMModelStatus Equatable conformance works for loading cases")
    func equatableForLoadingCases() {
        #expect(LLMModelStatus.loading(progress: 0.5) == LLMModelStatus.loading(progress: 0.5))
        #expect(LLMModelStatus.loading(progress: 0.5) != LLMModelStatus.loading(progress: 0.6))
        #expect(LLMModelStatus.loading(progress: 0.0) != LLMModelStatus.notLoaded)
    }

    @Test("LLMModelStatus Equatable conformance works for error cases")
    func equatableForErrorCases() {
        #expect(LLMModelStatus.error("same") == LLMModelStatus.error("same"))
        #expect(LLMModelStatus.error("error1") != LLMModelStatus.error("error2"))
        #expect(LLMModelStatus.error("test") != LLMModelStatus.notLoaded)
    }
}

// MARK: - LLMError Tests

@Suite("LLMError Tests")
struct LLMErrorTests {
    @Test("LLMError has all cases")
    func hasAllCases() {
        let allCases: [LLMError] = [
            .modelNotLoaded,
            .modelLoadFailed("reason"),
            .inferenceTimeout,
            .memoryPressure,
            .generationCancelled,
            .serviceUnavailable,
            .tokenizationFailed,
            .generationFailed("reason"),
        ]
        #expect(allCases.count == 8)
    }

    @Test("LLMError modelNotLoaded case exists")
    func modelNotLoadedCaseExists() {
        let error: LLMError = .modelNotLoaded
        switch error {
        case .modelNotLoaded:
            #expect(true)
        default:
            Issue.record("Should be modelNotLoaded case")
        }
    }

    @Test("LLMError inferenceTimeout case exists")
    func inferenceTimeoutCaseExists() {
        let error: LLMError = .inferenceTimeout
        switch error {
        case .inferenceTimeout:
            #expect(true)
        default:
            Issue.record("Should be inferenceTimeout case")
        }
    }

    @Test("LLMError memoryPressure case exists")
    func memoryPressureCaseExists() {
        let error: LLMError = .memoryPressure
        switch error {
        case .memoryPressure:
            #expect(true)
        default:
            Issue.record("Should be memoryPressure case")
        }
    }

    @Test("LLMError generationCancelled case exists")
    func generationCancelledCaseExists() {
        let error: LLMError = .generationCancelled
        switch error {
        case .generationCancelled:
            #expect(true)
        default:
            Issue.record("Should be generationCancelled case")
        }
    }

    @Test("LLMError serviceUnavailable case exists")
    func serviceUnavailableCaseExists() {
        let error: LLMError = .serviceUnavailable
        switch error {
        case .serviceUnavailable:
            #expect(true)
        default:
            Issue.record("Should be serviceUnavailable case")
        }
    }

    @Test("LLMError tokenizationFailed case exists")
    func tokenizationFailedCaseExists() {
        let error: LLMError = .tokenizationFailed
        switch error {
        case .tokenizationFailed:
            #expect(true)
        default:
            Issue.record("Should be tokenizationFailed case")
        }
    }

    @Test("LLMError modelLoadFailed stores reason")
    func modelLoadFailedStoresReason() {
        let error: LLMError = .modelLoadFailed("out of memory")
        switch error {
        case let .modelLoadFailed(reason):
            #expect(reason == "out of memory")
        default:
            Issue.record("Should be modelLoadFailed case")
        }
    }

    @Test("LLMError generationFailed stores reason")
    func generationFailedStoresReason() {
        let error: LLMError = .generationFailed("context overflow")
        switch error {
        case let .generationFailed(reason):
            #expect(reason == "context overflow")
        default:
            Issue.record("Should be generationFailed case")
        }
    }

    // MARK: - Error Description Tests

    @Test("LLMError errorDescription returns value for modelNotLoaded")
    func errorDescriptionForModelNotLoaded() throws {
        let error = LLMError.modelNotLoaded
        #expect(error.errorDescription != nil)
        #expect(try !#require(error.errorDescription?.isEmpty))
    }

    @Test("LLMError errorDescription returns value for modelLoadFailed")
    func errorDescriptionForModelLoadFailed() throws {
        let error = LLMError.modelLoadFailed("test reason")
        #expect(error.errorDescription != nil)
        #expect(try !#require(error.errorDescription?.isEmpty))
    }

    @Test("LLMError errorDescription returns value for inferenceTimeout")
    func errorDescriptionForInferenceTimeout() throws {
        let error = LLMError.inferenceTimeout
        #expect(error.errorDescription != nil)
        #expect(try !#require(error.errorDescription?.isEmpty))
    }

    @Test("LLMError errorDescription returns value for memoryPressure")
    func errorDescriptionForMemoryPressure() throws {
        let error = LLMError.memoryPressure
        #expect(error.errorDescription != nil)
        #expect(try !#require(error.errorDescription?.isEmpty))
    }

    @Test("LLMError errorDescription returns value for generationCancelled")
    func errorDescriptionForGenerationCancelled() throws {
        let error = LLMError.generationCancelled
        #expect(error.errorDescription != nil)
        #expect(try !#require(error.errorDescription?.isEmpty))
    }

    @Test("LLMError errorDescription returns value for serviceUnavailable")
    func errorDescriptionForServiceUnavailable() throws {
        let error = LLMError.serviceUnavailable
        #expect(error.errorDescription != nil)
        #expect(try !#require(error.errorDescription?.isEmpty))
    }

    @Test("LLMError errorDescription returns value for tokenizationFailed")
    func errorDescriptionForTokenizationFailed() throws {
        let error = LLMError.tokenizationFailed
        #expect(error.errorDescription != nil)
        #expect(try !#require(error.errorDescription?.isEmpty))
    }

    @Test("LLMError errorDescription returns value for generationFailed")
    func errorDescriptionForGenerationFailed() throws {
        let error = LLMError.generationFailed("test failure")
        #expect(error.errorDescription != nil)
        #expect(try !#require(error.errorDescription?.isEmpty))
    }

    @Test("LLMError errorDescription includes reason for modelLoadFailed")
    func errorDescriptionIncludesReasonForModelLoadFailed() {
        let reason = "specific error reason"
        let error = LLMError.modelLoadFailed(reason)
        // The description should contain or reference the reason
        #expect(error.errorDescription != nil)
    }

    @Test("LLMError errorDescription includes reason for generationFailed")
    func errorDescriptionIncludesReasonForGenerationFailed() {
        let reason = "generation failure reason"
        let error = LLMError.generationFailed(reason)
        // The description should contain or reference the reason
        #expect(error.errorDescription != nil)
    }

    // MARK: - Equatable Tests

    @Test("LLMError Equatable works for simple cases")
    func equatableForSimpleCases() {
        #expect(LLMError.modelNotLoaded == LLMError.modelNotLoaded)
        #expect(LLMError.inferenceTimeout == LLMError.inferenceTimeout)
        #expect(LLMError.memoryPressure == LLMError.memoryPressure)
        #expect(LLMError.generationCancelled == LLMError.generationCancelled)
        #expect(LLMError.serviceUnavailable == LLMError.serviceUnavailable)
        #expect(LLMError.tokenizationFailed == LLMError.tokenizationFailed)

        #expect(LLMError.modelNotLoaded != LLMError.inferenceTimeout)
        #expect(LLMError.memoryPressure != LLMError.serviceUnavailable)
    }

    @Test("LLMError Equatable works for modelLoadFailed with same reason")
    func equatableForModelLoadFailedSameReason() {
        #expect(
            LLMError.modelLoadFailed("same reason") == LLMError.modelLoadFailed("same reason")
        )
    }

    @Test("LLMError Equatable works for modelLoadFailed with different reasons")
    func equatableForModelLoadFailedDifferentReasons() {
        #expect(
            LLMError.modelLoadFailed("reason1") != LLMError.modelLoadFailed("reason2")
        )
    }

    @Test("LLMError Equatable works for generationFailed with same reason")
    func equatableForGenerationFailedSameReason() {
        #expect(
            LLMError.generationFailed("same reason") == LLMError.generationFailed("same reason")
        )
    }

    @Test("LLMError Equatable works for generationFailed with different reasons")
    func equatableForGenerationFailedDifferentReasons() {
        #expect(
            LLMError.generationFailed("reason1") != LLMError.generationFailed("reason2")
        )
    }

    @Test("LLMError different associated value types are not equal")
    func differentAssociatedValueTypesNotEqual() {
        #expect(LLMError.modelLoadFailed("test") != LLMError.generationFailed("test"))
        #expect(LLMError.modelNotLoaded != LLMError.modelLoadFailed("test"))
    }
}
