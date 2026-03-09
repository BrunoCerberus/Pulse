import EntropyCore

/// Transforms `StoryThreadDomainState` into `StoryThreadViewState` for the view layer.
struct StoryThreadViewStateReducer: ViewStateReducing {
    func reduce(domainState: StoryThreadDomainState) -> StoryThreadViewState {
        StoryThreadViewState(
            threads: domainState.threads.map { StoryThreadItem(from: $0) },
            isLoading: domainState.isLoading,
            isRefreshing: domainState.isRefreshing,
            showEmptyState: !domainState.isLoading && !domainState.isRefreshing && domainState.threads.isEmpty,
            errorMessage: domainState.error,
            generatingSummaryForID: domainState.generatingSummaryForID
        )
    }
}
