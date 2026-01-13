import EntropyCore
import Foundation

struct CollectionsViewStateReducer: ViewStateReducing {
    func reduce(domainState: CollectionsDomainState) -> CollectionsViewState {
        let hasNoCollections = domainState.featuredCollections.isEmpty
            && domainState.userCollections.isEmpty

        return CollectionsViewState(
            featuredCollections: domainState.featuredCollections.map { CollectionViewItem(from: $0) },
            userCollections: domainState.userCollections.map { CollectionViewItem(from: $0) },
            isLoading: domainState.isLoading,
            isRefreshing: domainState.isRefreshing,
            errorMessage: domainState.error,
            showEmptyState: !domainState.isLoading && !domainState.isRefreshing
                && domainState.hasLoadedInitialData && hasNoCollections,
            showEmptyUserCollections: domainState.userCollections.isEmpty,
            selectedCollection: domainState.selectedCollection,
            showCreateSheet: domainState.showCreateSheet,
            collectionToDelete: domainState.collectionToDelete
        )
    }
}
