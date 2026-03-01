import Foundation

/// Actions that can be dispatched to the Home domain interactor.
///
/// These actions represent all possible state changes in the Home feature,
/// triggered by user interactions or system events.
enum HomeDomainAction: Equatable {
    // MARK: - Data Loading

    /// Load initial data including hero news, trending headlines, and first page of articles.
    /// Dispatched when the Home view first appears.
    case loadInitialData

    /// Load the next page of headlines for infinite scroll.
    /// Dispatched when the user scrolls near the bottom of the article list.
    case loadMoreHeadlines

    /// Refresh all data (pull-to-refresh).
    /// Invalidates cache and reloads hero news, trending, and headlines.
    case refresh

    // MARK: - Article Selection

    /// Select an article to navigate to the detail view.
    /// - Parameter articleId: The unique identifier of the selected article.
    case selectArticle(articleId: String)

    /// Clear the selected article after navigation completes.
    /// Resets navigation state to prevent duplicate navigation.
    case clearSelectedArticle

    // MARK: - Article Actions

    /// Bookmark an article for offline reading.
    /// - Parameter articleId: The unique identifier of the article to bookmark.
    case bookmarkArticle(articleId: String)

    /// Share an article via the system share sheet.
    /// - Parameter articleId: The unique identifier of the article to share.
    case shareArticle(articleId: String)

    /// Clear the article selected for sharing after the share sheet dismisses.
    case clearArticleToShare

    // MARK: - Category Filtering

    /// Filter articles by a specific category.
    /// - Parameter category: The category to filter by, or `nil` to show all categories.
    case selectCategory(NewsCategory?)

    /// Toggle a topic in the user's followed topics list.
    /// - Parameter category: The category to toggle on/off.
    case toggleTopic(NewsCategory)

    /// Enter or exit topic editing mode.
    /// - Parameter editing: `true` to enter editing mode, `false` to exit.
    case setEditingTopics(Bool)

    // MARK: - Recently Read

    /// Select a recently read article to navigate to the detail view.
    /// - Parameter articleId: The unique identifier of the selected article.
    case selectRecentlyRead(articleId: String)
}
