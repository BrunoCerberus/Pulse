import Foundation

struct HomeViewStateReducer: ViewStateReducing {
    func reduce(domainState: HomeDomainState) -> HomeViewState {
        HomeViewState(
            breakingNews: domainState.breakingNews.map { ArticleViewItem(from: $0) },
            headlines: domainState.headlines.map { ArticleViewItem(from: $0) },
            isLoading: domainState.isLoading,
            isLoadingMore: domainState.isLoadingMore,
            isRefreshing: domainState.isRefreshing,
            errorMessage: domainState.error,
            showEmptyState: !domainState.isLoading && !domainState.isRefreshing && domainState.headlines.isEmpty && domainState.breakingNews.isEmpty
        )
    }
}
