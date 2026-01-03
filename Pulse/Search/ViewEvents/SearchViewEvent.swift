import Foundation

enum SearchViewEvent: Equatable {
    case onQueryChanged(String)
    case onSearch
    case onLoadMore
    case onClear
    case onSortChanged(SearchSortOption)
    case onArticleTapped(articleId: String)
    case onArticleNavigated
    case onSuggestionTapped(String)
}
