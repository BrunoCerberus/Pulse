import Foundation

enum CollectionsViewEvent: Equatable {
    case onAppear
    case onRefresh
    case onCollectionTapped(collectionId: String)
    case onCollectionNavigated
    case onCreateCollectionTapped
    case onCreateCollectionDismissed
    case onCreateCollection(name: String, description: String)
    case onDeleteCollectionTapped(collectionId: String)
    case onDeleteCollectionConfirmed
    case onDeleteCollectionCancelled
    case onAddArticle(article: Article, collectionId: String)
    case onRemoveArticle(articleId: String, collectionId: String)
    case onArticleRead(articleId: String, collectionId: String)
}
