import Foundation

/// View state for the Reading History screen.
struct ReadingHistoryViewState: Equatable {
    /// Read articles as view items for display.
    var articles: [ArticleViewItem]

    /// Indicates whether history is being loaded from storage.
    var isLoading: Bool

    /// Error message to display, if any.
    var errorMessage: String?

    /// Whether to show the empty state view (no reading history).
    var showEmptyState: Bool

    /// Article selected for navigation to detail view.
    var selectedArticle: Article?

    /// Creates the default initial state.
    static var initial: ReadingHistoryViewState {
        ReadingHistoryViewState(
            articles: [],
            isLoading: false,
            errorMessage: nil,
            showEmptyState: false,
            selectedArticle: nil
        )
    }
}
