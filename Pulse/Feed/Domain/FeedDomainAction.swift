import Foundation

/// Actions that can be dispatched to the Feed domain interactor.
///
/// These actions manage the AI-powered Daily Digest feature, including
/// LLM model lifecycle, article fetching, and digest generation.
enum FeedDomainAction: Equatable {
    // MARK: - Lifecycle

    /// Initialize the feed by loading latest articles and checking model status.
    /// Dispatched when the Feed view first appears.
    case loadInitialData

    // MARK: - Model Management

    /// Preload the LLM model into memory for faster digest generation.
    /// Should be called when the user is likely to generate a digest soon.
    case preloadModel

    /// Update the current status of the LLM model.
    /// - Parameter status: The new model status (notLoaded, loading, ready, error).
    case modelStatusChanged(LLMModelStatus)

    // MARK: - Articles

    /// Articles successfully loaded from the API.
    /// - Parameter articles: The fetched articles to be used for digest generation.
    case latestArticlesLoaded([Article])

    /// Failed to load articles from the API.
    /// - Parameter error: A human-readable error message.
    case latestArticlesFailed(String)

    // MARK: - Digest Generation

    /// Start generating a new AI digest from the loaded articles.
    /// Requires the LLM model to be loaded and articles to be available.
    case generateDigest

    /// A new token was received during streaming digest generation.
    /// - Parameter token: The generated text token to append to the digest.
    case digestTokenReceived(String)

    /// Digest generation completed successfully.
    /// - Parameter digest: The fully generated daily digest.
    case digestCompleted(DailyDigest)

    /// Digest generation failed.
    /// - Parameter error: A human-readable error message.
    case digestFailed(String)

    // MARK: - Navigation

    /// Select an article from the digest sources to navigate to detail view.
    /// - Parameter article: The article to display.
    case selectArticle(Article)

    /// Clear the selected article after navigation completes.
    case clearSelectedArticle

    // MARK: - State Changes

    /// Update the current generation state (idle, loading, generating, completed, error).
    /// - Parameter state: The new generation state.
    case generationStateChanged(FeedGenerationState)

    // MARK: - Error Handling

    /// Clear any displayed error message.
    case clearError
}
