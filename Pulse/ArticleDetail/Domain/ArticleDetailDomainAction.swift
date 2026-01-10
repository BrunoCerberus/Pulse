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

    // Summarization sheet
    case showSummarizationSheet
    case dismissSummarizationSheet
}
