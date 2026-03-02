import EntropyCore
import Foundation

/// Transforms `HomeDomainState` into `HomeViewState`.
///
/// This reducer is a pure function that:
/// - Converts Article models to ArticleViewItem view models
/// - Computes derived properties like `showEmptyState` and `showCategoryTabs`
/// - Passes through loading flags and error messages
///
/// ## State Transformations
/// - `breakingNews` → `[ArticleViewItem]` with animation indices
/// - `headlines` → `[ArticleViewItem]` with animation indices
/// - Empty state is shown when not loading and both lists are empty
/// - Category tabs are shown when user has followed topics
struct HomeViewStateReducer: ViewStateReducing {
    /// Reduces domain state to view state.
    /// - Parameter domainState: The current domain state from the interactor.
    /// - Returns: View state ready for consumption by SwiftUI views.
    func reduce(domainState: HomeDomainState) -> HomeViewState {
        HomeViewState(
            breakingNews: domainState.breakingNews.enumerated().map { index, article in
                ArticleViewItem(from: article, index: index, isRead: domainState.readArticleIDs.contains(article.id))
            },
            headlines: domainState.headlines.enumerated().map { index, article in
                ArticleViewItem(from: article, index: index, isRead: domainState.readArticleIDs.contains(article.id))
            },
            isLoading: domainState.isLoading,
            isLoadingMore: domainState.isLoadingMore,
            isRefreshing: domainState.isRefreshing,
            errorMessage: domainState.error,
            showEmptyState: !domainState.isLoading && !domainState.isRefreshing
                && domainState.headlines.isEmpty && domainState.breakingNews.isEmpty,
            selectedArticle: domainState.selectedArticle,
            articleToShare: domainState.articleToShare,
            selectedCategory: domainState.selectedCategory,
            followedTopics: domainState.followedTopics,
            showCategoryTabs: !domainState.followedTopics.isEmpty,
            allTopics: domainState.allTopics,
            isEditingTopics: domainState.isEditingTopics,
            isOfflineError: domainState.isOfflineError,
            recentlyRead: domainState.recentlyRead.enumerated().map { index, article in
                ArticleViewItem(from: article, index: index, isRead: true)
            }
        )
    }
}
