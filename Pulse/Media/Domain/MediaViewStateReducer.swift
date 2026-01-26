import EntropyCore
import Foundation

/// Transforms `MediaDomainState` into `MediaViewState`.
///
/// This reducer is a pure function that computes derived properties
/// and formats data for view consumption.
struct MediaViewStateReducer: ViewStateReducing {
    func reduce(domainState: MediaDomainState) -> MediaViewState {
        MediaViewState(
            selectedType: domainState.selectedType,
            featuredMedia: domainState.featuredMedia.enumerated().map { index, article in
                MediaViewItem(from: article, index: index)
            },
            mediaItems: domainState.mediaItems.enumerated().map { index, article in
                MediaViewItem(from: article, index: index)
            },
            isLoading: domainState.isLoading,
            isLoadingMore: domainState.isLoadingMore,
            isRefreshing: domainState.isRefreshing,
            errorMessage: domainState.error,
            showEmptyState: !domainState.isLoading && !domainState.isRefreshing
                && domainState.mediaItems.isEmpty && domainState.featuredMedia.isEmpty,
            selectedMedia: domainState.selectedMedia,
            mediaToShare: domainState.mediaToShare,
            mediaToPlay: domainState.mediaToPlay
        )
    }
}
