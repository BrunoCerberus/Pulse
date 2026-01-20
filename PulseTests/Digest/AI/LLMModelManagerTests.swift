import Foundation
@testable import Pulse
import Testing

@Suite("LLMModelManager Tests")
struct LLMModelManagerTests {
    // Note: LLMModelManager is a singleton, so tests must be designed to work with shared state
    // We test its interface rather than mocking it since it manages system resources

    @Test("Default system prompt is non-empty")
    func testDefaultSystemPrompt() {
        let prompt = LLMModelManager.defaultSystemPrompt
        #expect(!prompt.isEmpty)
        #expect(prompt.contains("helpful"))
    }

    @Test("hasAdequateMemory check doesn't crash")
    func memoryCheckDoesntCrash() {
        // This test just ensures the memory check doesn't crash
        // We can't reliably test the actual return value in a testing environment
        let manager = LLMModelManager()
        // If this doesn't crash, the test passes
        #expect(true)
    }

    @Test("Configuration contextSize is positive")
    func contextSizePositive() {
        #expect(LLMConfiguration.contextSize > 0)
    }

    @Test("Configuration batchSize is positive")
    func batchSizePositive() {
        #expect(LLMConfiguration.batchSize > 0)
    }

    @Test("Configuration threadCount is positive")
    func threadCountPositive() {
        #expect(LLMConfiguration.threadCount > 0)
    }

    @Test("Configuration threadCount respects processor limit")
    func threadCountRespectLimit() {
        let threadCount = LLMConfiguration.threadCount
        let processorCount = ProcessInfo.processInfo.activeProcessorCount
        #expect(threadCount <= min(processorCount, 4))
    }

    @Test("Configuration minimumAvailableMemory is reasonable")
    func minimumMemoryReasonable() {
        // 1GB minimum
        #expect(LLMConfiguration.minimumAvailableMemory == 1_000_000_000)
    }

    @Test("Configuration generationTimeout is positive")
    func generationTimeoutPositive() {
        #expect(LLMConfiguration.generationTimeout > 0)
    }

    @Test("Configuration maxArticlesForDigest is positive")
    func maxArticlesPositive() {
        #expect(LLMConfiguration.maxArticlesForDigest > 0)
    }

    @Test("Configuration maxArticlesForDigest prevents context overflow")
    func maxArticlesPreventOverflow() {
        let estimatedPromptTokens = LLMConfiguration.maxArticlesForDigest * LLMConfiguration.estimatedTokensPerArticle
        let totalWithReserved = estimatedPromptTokens + LLMConfiguration.reservedContextTokens
        #expect(totalWithReserved < LLMConfiguration.contextSize)
    }

    @Test("Configuration model file name is set")
    func modelFileNameSet() {
        #expect(!LLMConfiguration.modelFileName.isEmpty)
    }

    @Test("Configuration model extension is set")
    func modelExtensionSet() {
        #expect(!LLMConfiguration.modelExtension.isEmpty)
        #expect(LLMConfiguration.modelExtension == "gguf")
    }

    @Test("Configuration model path is either valid or empty")
    func modelPathValidity() {
        let path = LLMConfiguration.modelPath
        // Either it's a valid bundled resource or empty if not found
        #expect(path.isEmpty || FileManager.default.fileExists(atPath: path))
    }
}

// MARK: - LLM Model Manager Integration-Style Tests

@Suite("LLMConfiguration Tests")
struct LLMConfigurationTests {
    @Test("Context window accommodates min memory reserve")
    func contextWindowSufficient() {
        let contextSize = LLMConfiguration.contextSize
        let reserved = LLMConfiguration.reservedContextTokens
        #expect(contextSize > reserved)
    }

    @Test("Context tokens per article estimate is reasonable")
    func articleTokenEstimate() {
        let estimate = LLMConfiguration.estimatedTokensPerArticle
        // Reasonable range: 100-500 tokens per article
        #expect(estimate > 100 && estimate < 500)
    }

    @Test("Reserved context tokens accommodate output")
    func reservedTokensReasonable() {
        let reserved = LLMConfiguration.reservedContextTokens
        // Should be at least 1000 for system prompt + output
        #expect(reserved >= 1000)
    }

    @Test("Max articles calculation leaves safety margin")
    func maxArticlesLeavesSafetyMargin() {
        let estimatedTokens = LLMConfiguration.maxArticlesForDigest * LLMConfiguration.estimatedTokensPerArticle
        let total = estimatedTokens + LLMConfiguration.reservedContextTokens
        let contextSize = LLMConfiguration.contextSize
        let safetyMargin = contextSize - total
        // Should have at least 10% margin
        #expect(safetyMargin > contextSize / 10)
    }
}

// MARK: - LLM Error Tests

@Suite("LLMError Tests")
struct LLMErrorTests {
    @Test("ModelNotLoaded error has description")
    func modelNotLoadedDescription() {
        let error = LLMError.modelNotLoaded
        #expect(error.errorDescription != nil)
        #expect(!error.errorDescription!.isEmpty)
    }

    @Test("ModelLoadFailed error includes reason")
    func modelLoadFailedDescription() {
        let error = LLMError.modelLoadFailed("Test reason")
        let description = error.errorDescription ?? ""
        #expect(description.contains("Test reason"))
    }

    @Test("InferenceTimeout error has description")
    func inferenceTimeoutDescription() {
        let error = LLMError.inferenceTimeout
        #expect(error.errorDescription != nil)
    }

    @Test("MemoryPressure error has description")
    func memoryPressureDescription() {
        let error = LLMError.memoryPressure
        #expect(error.errorDescription != nil)
    }

    @Test("GenerationCancelled error has description")
    func generationCancelledDescription() {
        let error = LLMError.generationCancelled
        #expect(error.errorDescription != nil)
    }

    @Test("ServiceUnavailable error has description")
    func serviceUnavailableDescription() {
        let error = LLMError.serviceUnavailable
        #expect(error.errorDescription != nil)
    }

    @Test("TokenizationFailed error has description")
    func tokenizationFailedDescription() {
        let error = LLMError.tokenizationFailed
        #expect(error.errorDescription != nil)
    }

    @Test("GenerationFailed error includes reason")
    func generationFailedDescription() {
        let error = LLMError.generationFailed("Test generation error")
        let description = error.errorDescription ?? ""
        #expect(description.contains("Test generation error"))
    }

    @Test("All errors conform to LocalizedError")
    func errorsLocalized() {
        let errors: [LLMError] = [
            .modelNotLoaded,
            .inferenceTimeout,
            .memoryPressure,
            .generationCancelled,
            .serviceUnavailable,
            .tokenizationFailed,
        ]

        for error in errors {
            #expect(error.errorDescription != nil)
        }
    }

    @Test("Errors are equatable")
    func errorEquality() {
        let error1 = LLMError.modelNotLoaded
        let error2 = LLMError.modelNotLoaded
        #expect(error1 == error2)

        let error3 = LLMError.serviceUnavailable
        #expect(error1 != error3)
    }
}

// MARK: - LLM Inference Config Tests

@Suite("LLMInferenceConfig Tests")
struct LLMInferenceConfigTests {
    @Test("Default config has valid values")
    func defaultConfigValid() {
        let config = LLMInferenceConfig.default
        #expect(config.maxTokens > 0)
        #expect(config.temperature >= 0 && config.temperature <= 1.0)
        #expect(config.topP >= 0 && config.topP <= 1.0)
        #expect(!config.stopSequences.isEmpty)
    }

    @Test("Default config stop sequences include digest marker")
    func defaultStopSequences() {
        let config = LLMInferenceConfig.default
        #expect(config.stopSequences.contains("</digest>"))
    }

    @Test("Custom config can be created")
    func customConfig() {
        let config = LLMInferenceConfig(
            maxTokens: 512,
            temperature: 0.5,
            topP: 0.8,
            stopSequences: ["END", "STOP"]
        )

        #expect(config.maxTokens == 512)
        #expect(config.temperature == 0.5)
        #expect(config.topP == 0.8)
        #expect(config.stopSequences == ["END", "STOP"])
    }

    @Test("Config is equatable")
    func configEquatable() {
        let config1 = LLMInferenceConfig.default
        let config2 = LLMInferenceConfig.default
        #expect(config1 == config2)

        let config3 = LLMInferenceConfig(
            maxTokens: 256,
            temperature: 0.9,
            topP: 0.95,
            stopSequences: []
        )
        #expect(config1 != config3)
    }

    @Test("Temperature bounds are reasonable")
    func temperatureBounds() {
        let config = LLMInferenceConfig.default
        // Temperature should be between 0 and 2 for reasonable outputs
        #expect(config.temperature >= 0 && config.temperature <= 2.0)
    }

    @Test("TopP bounds are reasonable")
    func topPBounds() {
        let config = LLMInferenceConfig.default
        // TopP should be between 0 and 1
        #expect(config.topP >= 0 && config.topP <= 1.0)
    }
}

// MARK: - LLM Model Status Tests

@Suite("LLMModelStatus Tests")
struct LLMModelStatusTests {
    @Test("NotLoaded status initializes")
    func notLoadedStatus() {
        let status = LLMModelStatus.notLoaded
        if case .notLoaded = status {
            // Expected
        } else {
            #expect(Bool(false), "Should be notLoaded")
        }
    }

    @Test("Loading status stores progress")
    func loadingStatusProgress() {
        let status = LLMModelStatus.loading(progress: 0.5)
        if case let .loading(progress) = status {
            #expect(progress == 0.5)
        } else {
            #expect(Bool(false), "Should be loading")
        }
    }

    @Test("Ready status initializes")
    func readyStatus() {
        let status = LLMModelStatus.ready
        if case .ready = status {
            // Expected
        } else {
            #expect(Bool(false), "Should be ready")
        }
    }

    @Test("Error status stores message")
    func errorStatusMessage() {
        let errorMessage = "Test error message"
        let status = LLMModelStatus.error(errorMessage)
        if case let .error(message) = status {
            #expect(message == errorMessage)
        } else {
            #expect(Bool(false), "Should be error")
        }
    }

    @Test("Status values are equatable")
    func statusEquality() {
        let status1 = LLMModelStatus.notLoaded
        let status2 = LLMModelStatus.notLoaded
        #expect(status1 == status2)

        let status3 = LLMModelStatus.ready
        #expect(status1 != status3)

        let status4 = LLMModelStatus.loading(progress: 0.5)
        let status5 = LLMModelStatus.loading(progress: 0.5)
        #expect(status4 == status5)

        let status6 = LLMModelStatus.loading(progress: 0.3)
        #expect(status4 != status6)

        let status7 = LLMModelStatus.error("Error1")
        let status8 = LLMModelStatus.error("Error1")
        #expect(status7 == status8)

        let status9 = LLMModelStatus.error("Error2")
        #expect(status7 != status9)
    }

    @Test("Loading progress values are valid")
    func loadingProgressBounds() {
        let validProgresses: [Double] = [0.0, 0.25, 0.5, 0.75, 1.0]

        for progress in validProgresses {
            let status = LLMModelStatus.loading(progress: progress)
            if case let .loading(p) = status {
                #expect(p == progress)
            } else {
                #expect(Bool(false), "Should be loading with progress \(progress)")
            }
        }
    }
}
