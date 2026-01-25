import Foundation

struct ArticleDetailViewState: Equatable {
    let article: Article

    // Content processing
    var isProcessingContent: Bool
    var processedContent: AttributedString?
    var processedDescription: AttributedString?

    /// Bookmark state
    var isBookmarked: Bool

    /// Share sheet
    var showShareSheet: Bool

    /// Summarization sheet visibility
    var showSummarizationSheet: Bool

    static func initial(article: Article) -> ArticleDetailViewState {
        ArticleDetailViewState(
            article: article,
            isProcessingContent: true,
            processedContent: nil,
            processedDescription: nil,
            isBookmarked: false,
            showShareSheet: false,
            showSummarizationSheet: false
        )
    }
}
