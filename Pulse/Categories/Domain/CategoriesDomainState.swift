import Foundation

struct CategoriesDomainState: Equatable {
    var selectedCategory: NewsCategory?
    var articles: [Article]
    var isLoading: Bool
    var isLoadingMore: Bool
    var error: String?
    var currentPage: Int
    var hasMorePages: Bool
    var hasLoadedInitialData: Bool

    static var initial: CategoriesDomainState {
        CategoriesDomainState(
            selectedCategory: nil,
            articles: [],
            isLoading: false,
            isLoadingMore: false,
            error: nil,
            currentPage: 1,
            hasMorePages: true,
            hasLoadedInitialData: false
        )
    }
}
