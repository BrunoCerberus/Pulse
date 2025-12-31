import Foundation

struct HomeDomainState: Equatable {
    var breakingNews: [Article]
    var headlines: [Article]
    var isLoading: Bool
    var isLoadingMore: Bool
    var isRefreshing: Bool
    var error: String?
    var currentPage: Int
    var hasMorePages: Bool
    var hasLoadedInitialData: Bool
    var selectedArticle: Article?
    var articleToShare: Article?

    static var initial: HomeDomainState {
        HomeDomainState(
            breakingNews: [],
            headlines: [],
            isLoading: false,
            isLoadingMore: false,
            isRefreshing: false,
            error: nil,
            currentPage: 1,
            hasMorePages: true,
            hasLoadedInitialData: false,
            selectedArticle: nil,
            articleToShare: nil
        )
    }
}
