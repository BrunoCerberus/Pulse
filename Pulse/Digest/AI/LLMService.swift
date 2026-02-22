import Combine
import Foundation

/// Configuration for LLM inference
struct LLMInferenceConfig: Equatable {
    let maxTokens: Int
    let temperature: Float
    let topP: Float
    let stopSequences: [String]

    static var `default`: LLMInferenceConfig {
        LLMInferenceConfig(
            maxTokens: 1024,
            temperature: 0.7,
            topP: 0.9,
            stopSequences: ["</digest>", "\n\n\n"]
        )
    }
}

/// Status of the LLM model
enum LLMModelStatus: Equatable {
    case notLoaded
    case loading(progress: Double)
    case ready
    case error(String)
}

/// Errors that can occur during LLM operations
enum LLMError: Error, LocalizedError, Equatable {
    case modelNotLoaded
    case modelLoadFailed(String)
    case inferenceTimeout
    case memoryPressure
    case generationCancelled
    case serviceUnavailable
    case tokenizationFailed
    case generationFailed(String)

    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return AppLocalization.shared.localized("llm.error.model_not_loaded")
        case let .modelLoadFailed(reason):
            return AppLocalization.shared.localized("llm.error.model_load_failed") + " " + reason
        case .inferenceTimeout:
            return AppLocalization.shared.localized("llm.error.inference_timeout")
        case .memoryPressure:
            return AppLocalization.shared.localized("llm.error.memory_pressure")
        case .generationCancelled:
            return AppLocalization.shared.localized("llm.error.generation_cancelled")
        case .serviceUnavailable:
            return AppLocalization.shared.localized("llm.error.service_unavailable")
        case .tokenizationFailed:
            return AppLocalization.shared.localized("llm.error.tokenization_failed")
        case let .generationFailed(reason):
            return AppLocalization.shared.localized("llm.error.generation_failed") + " " + reason
        }
    }
}

/// Protocol for LLM operations
protocol LLMService {
    /// Publisher for current model status
    var modelStatusPublisher: AnyPublisher<LLMModelStatus, Never> { get }

    /// Check if model is loaded and ready
    var isModelLoaded: Bool { get }

    /// Load the model into memory
    func loadModel() async throws

    /// Unload model to free memory
    func unloadModel() async

    /// Generate text from prompt (returns complete result)
    func generate(
        prompt: String,
        systemPrompt: String?,
        config: LLMInferenceConfig
    ) -> AnyPublisher<String, Error>

    /// Stream generation token by token
    func generateStream(
        prompt: String,
        systemPrompt: String?,
        config: LLMInferenceConfig
    ) -> AsyncThrowingStream<String, Error>

    /// Cancel ongoing generation
    func cancelGeneration()
}
