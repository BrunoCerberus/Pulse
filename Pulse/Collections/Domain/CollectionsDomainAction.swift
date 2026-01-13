import Foundation

enum CollectionsDomainAction: Equatable {
    case loadInitialData
    case refresh
    case selectCollection(collectionId: String)
    case clearSelectedCollection
    case showCreateCollectionSheet
    case hideCreateCollectionSheet
    case createCollection(name: String, description: String)
    case deleteCollection(collectionId: String)
    case confirmDeleteCollection
    case cancelDeleteCollection
    case addArticleToCollection(article: Article, collectionId: String)
    case removeArticleFromCollection(articleId: String, collectionId: String)
    case markArticleAsRead(articleId: String, collectionId: String)
}
