import EntropyCore
import Foundation

struct CollectionsEventActionMap: DomainEventActionMap {
    func map(event: CollectionsViewEvent) -> CollectionsDomainAction? {
        switch event {
        case .onAppear:
            return .loadInitialData
        case .onRefresh:
            return .refresh
        case let .onCollectionTapped(collectionId):
            return .selectCollection(collectionId: collectionId)
        case .onCollectionNavigated:
            return .clearSelectedCollection
        case .onCreateCollectionTapped:
            return .showCreateCollectionSheet
        case .onCreateCollectionDismissed:
            return .hideCreateCollectionSheet
        case let .onCreateCollection(name, description):
            return .createCollection(name: name, description: description)
        case let .onDeleteCollectionTapped(collectionId):
            return .deleteCollection(collectionId: collectionId)
        case .onDeleteCollectionConfirmed:
            return .confirmDeleteCollection
        case .onDeleteCollectionCancelled:
            return .cancelDeleteCollection
        case let .onAddArticle(article, collectionId):
            return .addArticleToCollection(article: article, collectionId: collectionId)
        case let .onRemoveArticle(articleId, collectionId):
            return .removeArticleFromCollection(articleId: articleId, collectionId: collectionId)
        case let .onArticleRead(articleId, collectionId):
            return .markArticleAsRead(articleId: articleId, collectionId: collectionId)
        }
    }
}
