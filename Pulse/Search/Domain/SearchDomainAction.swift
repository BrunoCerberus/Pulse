import Foundation

/// Actions that can be dispatched to the Search domain interactor.
///
/// These actions handle search query management, result pagination,
/// sorting, and article selection for navigation.
enum SearchDomainAction: Equatable {
    // MARK: - Query Management

    /// Update the current search query text.
    /// Triggers debounced search after 300ms of inactivity.
    /// - Parameter query: The new search query string.
    case updateQuery(String)

    /// Execute the search with the current query.
    /// Dispatched after debounce timeout or when user presses search.
    case search

    /// Load the next page of search results.
    /// Dispatched when user scrolls near the bottom of results.
    case loadMore

    /// Clear all search results and reset to empty state.
    /// Dispatched when user clears the search field.
    case clearResults

    // MARK: - Sorting

    /// Change the sort order for search results.
    /// - Parameter option: The new sort option (relevance, newest, oldest).
    case setSortOption(SearchSortOption)

    // MARK: - Navigation

    /// Select an article from search results to navigate to detail view.
    /// - Parameter articleId: The unique identifier of the selected article.
    case selectArticle(articleId: String)

    /// Clear the selected article after navigation completes.
    case clearSelectedArticle

    // MARK: - Article Actions

    /// Bookmark or unbookmark an article.
    case bookmarkArticle(articleId: String)

    /// Share an article via the system share sheet.
    case shareArticle(articleId: String)

    /// Clear the article to share after the share sheet is dismissed.
    case clearArticleToShare
}
