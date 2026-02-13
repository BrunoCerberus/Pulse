import Foundation

/// Actions that can be dispatched to the Summarization domain interactor.
///
/// These actions control the on-device AI article summarization feature,
/// managing the LLM model lifecycle and streaming summary generation.
enum SummarizationDomainAction: Equatable {
    // MARK: - Summarization Control

    /// Start generating a summary for the current article.
    /// Requires the LLM model to be loaded and article content available.
    case startSummarization

    /// Cancel an in-progress summarization.
    /// Stops token generation and resets to idle state.
    case cancelSummarization

    // MARK: - State Updates

    /// Update the current summarization state.
    /// - Parameter state: The new state (idle, loading, generating, completed, error).
    case summarizationStateChanged(SummarizationState)

    /// A new token was received during streaming summarization.
    /// - Parameter token: The generated text token to append to the summary.
    case summarizationTokenReceived(String)

    // MARK: - Model Status

    /// Update the current status of the LLM model.
    /// - Parameter status: The new model status (notLoaded, loading, ready, error).
    case modelStatusChanged(LLMModelStatus)
}
