import Foundation

enum FeedDomainAction: Equatable {
    /// Lifecycle
    case loadInitialData

    // Model management
    case preloadModel
    case modelStatusChanged(LLMModelStatus)

    // Articles
    case latestArticlesLoaded([Article])
    case latestArticlesFailed(String)

    // Digest generation
    case generateDigest
    case digestTokenReceived(String)
    case digestCompleted(DailyDigest)
    case digestFailed(String)

    // Navigation
    case selectArticle(Article)
    case clearSelectedArticle

    /// State changes
    case generationStateChanged(FeedGenerationState)

    /// Error handling
    case clearError
}
