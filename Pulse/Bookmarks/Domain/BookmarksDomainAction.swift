import Foundation

/// Actions that can be dispatched to the Bookmarks domain interactor.
///
/// These actions manage the user's saved articles for offline reading,
/// including loading, removing, and navigating to bookmarked content.
enum BookmarksDomainAction: Equatable {
    // MARK: - Data Loading

    /// Load all bookmarked articles from local storage.
    /// Dispatched when the Bookmarks view first appears.
    case loadBookmarks

    /// Refresh the bookmarks list from storage.
    /// Dispatched on pull-to-refresh to sync with any external changes.
    case refresh

    // MARK: - Bookmark Management

    /// Remove an article from bookmarks.
    /// - Parameter articleId: The unique identifier of the article to remove.
    case removeBookmark(articleId: String)

    // MARK: - Navigation

    /// Select a bookmarked article to navigate to detail view.
    /// - Parameter articleId: The unique identifier of the selected article.
    case selectArticle(articleId: String)

    /// Clear the selected article after navigation completes.
    case clearSelectedArticle

    // MARK: - Sharing

    /// Share an article via the system share sheet.
    case shareArticle(articleId: String)

    /// Clear the article to share after the share sheet is dismissed.
    case clearArticleToShare
}
