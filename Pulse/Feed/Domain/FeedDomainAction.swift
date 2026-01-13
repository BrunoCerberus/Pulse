import Foundation

enum FeedDomainAction: Equatable {
    // Lifecycle
    case loadInitialData
    case refresh

    // Model management
    case modelStatusChanged(LLMModelStatus)

    // History
    case readingHistoryLoaded([Article])
    case readingHistoryFailed(String)

    // Digest generation
    case generateDigest
    case digestTokenReceived(String)
    case digestCompleted(DailyDigest)
    case digestFailed(String)
    case cancelGeneration

    // Navigation
    case selectArticle(Article)
    case clearSelectedArticle

    // State changes
    case generationStateChanged(FeedGenerationState)

    // Error handling
    case clearError
}
