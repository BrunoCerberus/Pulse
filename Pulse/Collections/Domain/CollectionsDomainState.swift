import Foundation

struct CollectionsDomainState: Equatable {
    var featuredCollections: [Collection]
    var userCollections: [Collection]
    var isLoading: Bool
    var isRefreshing: Bool
    var error: String?
    var hasLoadedInitialData: Bool
    var selectedCollection: Collection?
    var showCreateSheet: Bool
    var collectionToDelete: Collection?

    static var initial: CollectionsDomainState {
        CollectionsDomainState(
            featuredCollections: [],
            userCollections: [],
            isLoading: false,
            isRefreshing: false,
            error: nil,
            hasLoadedInitialData: false,
            selectedCollection: nil,
            showCreateSheet: false,
            collectionToDelete: nil
        )
    }
}
