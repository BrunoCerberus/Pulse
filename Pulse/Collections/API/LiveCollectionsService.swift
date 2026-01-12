import Combine
import EntropyCore
import Foundation

final class LiveCollectionsService: APIRequest, CollectionsService {
    private let storageService: StorageService

    init(storageService: StorageService) {
        self.storageService = storageService
    }

    func fetchFeaturedCollections() -> AnyPublisher<[Collection], Error> {
        let publishers = CollectionDefinition.all.map { definition in
            fetchArticlesForDefinition(definition)
                .map { articles in
                    self.createCollectionFromDefinition(definition, articles: articles)
                }
                .eraseToAnyPublisher()
        }

        return Publishers.MergeMany(publishers)
            .collect()
            .map { collections in
                collections.sorted { $0.isPremium == $1.isPremium ? $0.name < $1.name : !$0.isPremium }
            }
            .eraseToAnyPublisher()
    }

    func fetchUserCollections() -> AnyPublisher<[Collection], Error> {
        Future { [weak self] promise in
            guard let self else {
                promise(.success([]))
                return
            }
            Task {
                do {
                    let collections = try await self.loadUserCollectionsFromStorage()
                    promise(.success(collections))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func fetchCollection(id: String) -> AnyPublisher<Collection?, Error> {
        if let definition = CollectionDefinition.all.first(where: { $0.id == id }) {
            return fetchArticlesForDefinition(definition)
                .map { [weak self] articles in
                    self?.createCollectionFromDefinition(definition, articles: articles)
                }
                .eraseToAnyPublisher()
        }

        return Future { [weak self] promise in
            guard let self else {
                promise(.success(nil))
                return
            }
            Task {
                do {
                    let collection = try await self.loadCollectionFromStorage(id: id)
                    promise(.success(collection))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func createCollection(name: String, description: String) -> AnyPublisher<Collection, Error> {
        let collection = Collection.userCollection(name: name, description: description)

        return Future { [weak self] promise in
            guard let self else {
                promise(.failure(CollectionsServiceError.serviceUnavailable))
                return
            }
            Task {
                do {
                    try await self.saveCollectionToStorage(collection)
                    promise(.success(collection))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func updateCollection(_ collection: Collection) -> AnyPublisher<Collection, Error> {
        Future { [weak self] promise in
            guard let self else {
                promise(.failure(CollectionsServiceError.serviceUnavailable))
                return
            }
            Task {
                do {
                    try await self.saveCollectionToStorage(collection)
                    promise(.success(collection))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func deleteCollection(id: String) -> AnyPublisher<Void, Error> {
        Future { [weak self] promise in
            guard let self else {
                promise(.failure(CollectionsServiceError.serviceUnavailable))
                return
            }
            Task {
                do {
                    try await self.deleteCollectionFromStorage(id: id)
                    promise(.success(()))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func addArticleToCollection(_ article: Article, collectionID: String) -> AnyPublisher<Collection, Error> {
        Future { [weak self] promise in
            guard let self else {
                promise(.failure(CollectionsServiceError.serviceUnavailable))
                return
            }
            Task {
                do {
                    guard var collection = try await self.loadCollectionFromStorage(id: collectionID) else {
                        promise(.failure(CollectionsServiceError.collectionNotFound))
                        return
                    }
                    collection = collection.withArticle(article)
                    try await self.saveCollectionToStorage(collection)
                    promise(.success(collection))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func removeArticleFromCollection(articleID: String, collectionID: String) -> AnyPublisher<Collection, Error> {
        Future { [weak self] promise in
            guard let self else {
                promise(.failure(CollectionsServiceError.serviceUnavailable))
                return
            }
            Task {
                do {
                    guard var collection = try await self.loadCollectionFromStorage(id: collectionID) else {
                        promise(.failure(CollectionsServiceError.collectionNotFound))
                        return
                    }
                    collection = collection.withoutArticle(articleID)
                    try await self.saveCollectionToStorage(collection)
                    promise(.success(collection))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func markArticleAsRead(articleID: String, collectionID: String) -> AnyPublisher<Collection, Error> {
        Future { [weak self] promise in
            guard let self else {
                promise(.failure(CollectionsServiceError.serviceUnavailable))
                return
            }
            Task {
                do {
                    guard var collection = try await self.loadCollectionFromStorage(id: collectionID) else {
                        promise(.failure(CollectionsServiceError.collectionNotFound))
                        return
                    }
                    collection = collection.markingArticleAsRead(articleID)
                    try await self.saveCollectionToStorage(collection)
                    promise(.success(collection))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    // MARK: - Private Helpers

    private func fetchArticlesForDefinition(_ definition: CollectionDefinition) -> AnyPublisher<[Article], Error> {
        fetchRequest(
            target: GuardianAPI.search(
                query: definition.query,
                section: definition.section,
                page: 1,
                pageSize: definition.articleCount,
                orderBy: definition.orderBy
            ),
            dataType: GuardianResponse.self
        )
        .map { response in
            response.response.results.compactMap { $0.toArticle() }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    private func createCollectionFromDefinition(_ definition: CollectionDefinition, articles: [Article]) -> Collection {
        Collection(
            id: definition.id,
            name: definition.name,
            description: definition.description,
            imageURL: nil,
            articles: articles,
            articleCount: articles.count,
            readArticleIDs: [],
            collectionType: definition.collectionType,
            isPremium: definition.isPremium,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    // MARK: - Storage Operations

    private func loadUserCollectionsFromStorage() async throws -> [Collection] {
        try await storageService.fetchUserCollections()
    }

    private func loadCollectionFromStorage(id: String) async throws -> Collection? {
        try await storageService.fetchCollection(id: id)
    }

    private func saveCollectionToStorage(_ collection: Collection) async throws {
        try await storageService.saveCollection(collection)
    }

    private func deleteCollectionFromStorage(id: String) async throws {
        try await storageService.deleteCollection(id: id)
    }
}

enum CollectionsServiceError: Error, LocalizedError {
    case serviceUnavailable
    case collectionNotFound
    case articleNotFound

    var errorDescription: String? {
        switch self {
        case .serviceUnavailable:
            return "Collections service is unavailable"
        case .collectionNotFound:
            return "Collection not found"
        case .articleNotFound:
            return "Article not found"
        }
    }
}
