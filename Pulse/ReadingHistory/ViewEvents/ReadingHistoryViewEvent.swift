import Foundation

/// Events that can be triggered from the Reading History view.
enum ReadingHistoryViewEvent: Equatable {
    /// View appeared, should load history.
    case onAppear

    /// User tapped the clear history button.
    case onClearHistoryTapped

    /// User tapped on an article.
    /// - Parameter articleId: The unique identifier of the tapped article.
    case onArticleTapped(articleId: String)

    /// Navigation to article detail completed.
    case onArticleNavigated

    /// User tapped bookmark on an article.
    case onBookmarkTapped(articleId: String)

    /// User tapped share on an article.
    case onShareTapped(articleId: String)

    /// Share sheet was dismissed.
    case onShareDismissed
}
