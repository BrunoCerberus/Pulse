import Foundation

struct HomeDomainState: Equatable {
    var breakingNews: [Article]
    var headlines: [Article]
    var isLoading: Bool
    var isLoadingMore: Bool
    var error: String?
    var currentPage: Int
    var hasMorePages: Bool

    static var initial: HomeDomainState {
        HomeDomainState(
            breakingNews: [],
            headlines: [],
            isLoading: false,
            isLoadingMore: false,
            error: nil,
            currentPage: 1,
            hasMorePages: true
        )
    }
}
