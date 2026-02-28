import Foundation

/// Actions that can be dispatched to the Reading History domain interactor.
enum ReadingHistoryDomainAction: Equatable {
    /// Load all read articles from local storage.
    case loadHistory

    /// Clear all reading history.
    case clearHistory

    /// Select an article to navigate to detail view.
    /// - Parameter articleId: The unique identifier of the selected article.
    case selectArticle(articleId: String)

    /// Clear the selected article after navigation completes.
    case clearSelectedArticle

    /// Bookmark or unbookmark an article.
    case bookmarkArticle(articleId: String)

    /// Share an article via the system share sheet.
    case shareArticle(articleId: String)

    /// Clear the article to share after the share sheet is dismissed.
    case clearArticleToShare
}
