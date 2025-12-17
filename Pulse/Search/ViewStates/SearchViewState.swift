import Foundation

struct SearchViewState: Equatable {
    var query: String
    var results: [ArticleViewItem]
    var suggestions: [String]
    var isLoading: Bool
    var isLoadingMore: Bool
    var errorMessage: String?
    var showEmptyState: Bool
    var sortOption: SearchSortOption

    static var initial: SearchViewState {
        SearchViewState(
            query: "",
            results: [],
            suggestions: [],
            isLoading: false,
            isLoadingMore: false,
            errorMessage: nil,
            showEmptyState: false,
            sortOption: .relevancy
        )
    }
}
