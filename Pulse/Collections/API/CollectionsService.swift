import Combine
import Foundation

protocol CollectionsService {
    func fetchFeaturedCollections() -> AnyPublisher<[Collection], Error>
    func fetchUserCollections() -> AnyPublisher<[Collection], Error>
    func fetchCollection(id: String) -> AnyPublisher<Collection?, Error>

    func createCollection(name: String, description: String) -> AnyPublisher<Collection, Error>
    func updateCollection(_ collection: Collection) -> AnyPublisher<Collection, Error>
    func deleteCollection(id: String) -> AnyPublisher<Void, Error>

    func addArticleToCollection(_ article: Article, collectionID: String) -> AnyPublisher<Collection, Error>
    func removeArticleFromCollection(articleID: String, collectionID: String) -> AnyPublisher<Collection, Error>
    func markArticleAsRead(articleID: String, collectionID: String) -> AnyPublisher<Collection, Error>
}
