import Foundation

enum SearchDomainAction: Equatable {
    case updateQuery(String)
    case search
    case loadMore
    case clearResults
    case setSortOption(SearchSortOption)
    case selectArticle(Article)
    case clearSelectedArticle
}
