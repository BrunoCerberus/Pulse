import Foundation

enum HomeDomainAction: Equatable {
    case loadInitialData
    case loadMoreHeadlines
    case refresh
    case selectArticle(articleId: String)
    case clearSelectedArticle
    case bookmarkArticle(articleId: String)
    case shareArticle(articleId: String)
    case clearArticleToShare
    case selectCategory(NewsCategory?)
    case toggleTopic(NewsCategory)
    case setEditingTopics(Bool)
}
