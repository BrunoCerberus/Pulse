import Foundation

enum ArticleDetailDomainAction: Equatable {
    // Lifecycle
    case onAppear

    // Bookmark
    case toggleBookmark
    case bookmarkStatusLoaded(Bool)

    // Share
    case showShareSheet
    case dismissShareSheet

    // Browser
    case openInBrowser

    // Content processing
    case contentProcessingCompleted(content: AttributedString?, description: AttributedString?)

    // Summarization
    case showSummarizationSheet
    case dismissSummarizationSheet
    case startSummarization
    case cancelSummarization
    case summarizationStateChanged(SummarizationState)
    case summarizationTokenReceived(String)
    case modelStatusChanged(LLMModelStatus)
}
