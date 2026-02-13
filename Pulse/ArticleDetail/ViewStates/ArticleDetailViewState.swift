import Foundation

/// View state for the Article Detail screen.
///
/// This state is computed from `ArticleDetailDomainState` via `ArticleDetailViewStateReducer`
/// and consumed directly by the SwiftUI view layer.
struct ArticleDetailViewState: Equatable {
    /// The article being displayed.
    let article: Article

    // MARK: - Content Processing

    /// Indicates whether the article content is being processed into attributed strings.
    var isProcessingContent: Bool

    /// Formatted article body content as attributed string (supports rich text).
    var processedContent: AttributedString?

    /// Formatted article description/excerpt as attributed string.
    var processedDescription: AttributedString?

    // MARK: - User Actions

    /// Whether the article is currently bookmarked by the user.
    var isBookmarked: Bool

    /// Whether to show the system share sheet.
    var showShareSheet: Bool

    /// Whether to show the AI summarization sheet (Premium feature).
    var showSummarizationSheet: Bool

    /// Creates the initial state for a given article.
    /// - Parameter article: The article to display.
    /// - Returns: Initial view state with content processing enabled.
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
