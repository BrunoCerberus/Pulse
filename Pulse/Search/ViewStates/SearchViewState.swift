import Foundation

struct SearchViewState: Equatable {
    var query: String
    var results: [ArticleViewItem]
    var suggestions: [String]
    var isLoading: Bool
    var isLoadingMore: Bool
    var isSorting: Bool
    var errorMessage: String?
    var showNoResults: Bool
    var hasSearched: Bool
    var sortOption: SearchSortOption
    var selectedArticle: Article?

    static var initial: SearchViewState {
        SearchViewState(
            query: "",
            results: [],
            suggestions: [],
            isLoading: false,
            isLoadingMore: false,
            isSorting: false,
            errorMessage: nil,
            showNoResults: false,
            hasSearched: false,
            sortOption: .relevancy,
            selectedArticle: nil
        )
    }
}
