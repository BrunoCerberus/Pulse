import Combine
import Foundation

/// Errors for feed service operations
enum FeedServiceError: Error, LocalizedError {
    case noReadingHistory
    case generationFailed(String)
    case modelNotReady
    case insufficientMemory

    var errorDescription: String? {
        switch self {
        case .noReadingHistory:
            return "No articles read in the past 48 hours"
        case let .generationFailed(reason):
            return "Failed to generate digest: \(reason)"
        case .modelNotReady:
            return "AI model is not ready"
        case .insufficientMemory:
            return "Not enough memory to generate digest"
        }
    }
}

/// Protocol for daily digest feed operations
protocol FeedService {
    /// Publisher for current LLM model status
    var modelStatusPublisher: AnyPublisher<LLMModelStatus, Never> { get }

    /// Check if model is loaded and ready
    var isModelReady: Bool { get }

    /// Load the LLM model if not already loaded
    func loadModelIfNeeded() async throws

    /// Fetch today's cached digest if available
    func fetchTodaysDigest() -> DailyDigest?

    /// Generate a daily digest from reading history
    /// Returns a stream of tokens for live UI updates
    func generateDigest(from articles: [Article]) -> AsyncThrowingStream<String, Error>

    /// Save generated digest for the day
    func saveDigest(_ digest: DailyDigest)
}
