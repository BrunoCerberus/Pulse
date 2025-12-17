import Foundation

enum HomeDomainAction: Equatable {
    case loadInitialData
    case loadMoreHeadlines
    case refresh
    case selectArticle(Article)
    case bookmarkArticle(Article)
    case shareArticle(Article)
}
