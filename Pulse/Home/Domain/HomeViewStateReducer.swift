import EntropyCore
import Foundation

struct HomeViewStateReducer: ViewStateReducing {
    func reduce(domainState: HomeDomainState) -> HomeViewState {
        HomeViewState(
            breakingNews: domainState.breakingNews.enumerated().map { index, article in
                ArticleViewItem(from: article, index: index)
            },
            headlines: domainState.headlines.enumerated().map { index, article in
                ArticleViewItem(from: article, index: index)
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
            isEditingTopics: domainState.isEditingTopics
        )
    }
}
