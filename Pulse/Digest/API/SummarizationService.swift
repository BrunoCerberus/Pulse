import Combine
import Foundation

/// Protocol for article summarization operations
protocol SummarizationService {
    /// Publisher for current model status
    var modelStatusPublisher: AnyPublisher<LLMModelStatus, Never> { get }

    /// Check if model is loaded and ready
    var isModelLoaded: Bool { get }

    /// Load the model if not already loaded
    func loadModelIfNeeded() async throws

    /// Summarize a single article with streaming tokens
    func summarize(article: Article) -> AsyncThrowingStream<String, Error>

    /// Cancel ongoing summarization
    func cancelSummarization()
}
