import Foundation

/// Domain actions for the Digest feature
enum DigestDomainAction: Equatable {
    /// Load the LLM model if not already loaded
    case loadModelIfNeeded

    /// Select a content source for digest generation
    case selectSource(DigestSource)

    /// Load articles from the selected source
    case loadArticlesForSource

    /// Generate the AI digest from loaded articles
    case generateDigest

    /// Cancel ongoing digest generation
    case cancelGeneration

    /// Clear the generated digest to start over
    case clearDigest

    /// Update the model status (from LLMService publisher)
    case updateModelStatus(LLMModelStatus)

    /// Unload the model to free memory
    case unloadModel

    /// Retry the last failed generation
    case retryGeneration
}
