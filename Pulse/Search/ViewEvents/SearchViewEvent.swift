import Foundation

enum SearchViewEvent: Equatable {
    case onQueryChanged(String)
    case onSearch
    case onLoadMore
    case onClear
    case onSortChanged(SearchSortOption)
    case onArticleTapped(Article)
    case onArticleNavigated
    case onSuggestionTapped(String)
}
