import Combine
import Foundation

/// Live implementation of SummarizationService for AI-powered article summarization.
///
/// This service manages on-device article summarization, including:
/// - LLM model lifecycle delegation to `LLMService`
/// - Prompt building via `ArticleSummaryPromptBuilder`
/// - Streaming summary generation with cancellation support
///
/// ## Usage
/// The service is typically used from `SummarizationDomainInteractor`:
/// ```swift
/// try await summarizationService.loadModelIfNeeded()
/// for try await token in summarizationService.summarize(article: article) {
///     print(token)
/// }
/// ```
///
/// ## Premium Feature
/// This service powers the Premium article summarization feature.
final class LiveSummarizationService: SummarizationService {
    private let llmService: LLMService

    init(llmService: LLMService? = nil) {
        self.llmService = llmService ?? LiveLLMService()
    }

    var modelStatusPublisher: AnyPublisher<LLMModelStatus, Never> {
        llmService.modelStatusPublisher
    }

    var isModelLoaded: Bool {
        llmService.isModelLoaded
    }

    func loadModelIfNeeded() async throws {
        guard !isModelLoaded else { return }
        try await llmService.loadModel()
    }

    func summarize(article: Article) -> AsyncThrowingStream<String, Error> {
        let prompt = ArticleSummaryPromptBuilder.buildPrompt(for: article)
        let systemPrompt = ArticleSummaryPromptBuilder.systemPrompt
        let config = LLMInferenceConfig.summarization
        return llmService.generateStream(prompt: prompt, systemPrompt: systemPrompt, config: config)
    }

    func cancelSummarization() {
        llmService.cancelGeneration()
    }
}

extension LLMInferenceConfig {
    static var summarization: LLMInferenceConfig {
        LLMInferenceConfig(
            maxTokens: 1024,
            temperature: 0.5,
            topP: 0.9,
            stopSequences: ["</summary>", "\n\n\n"]
        )
    }
}
