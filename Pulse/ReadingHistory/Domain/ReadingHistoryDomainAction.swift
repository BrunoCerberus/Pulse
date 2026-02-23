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
}
