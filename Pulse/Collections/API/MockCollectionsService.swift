import Combine
import Foundation

final class MockCollectionsService: CollectionsService {
    var mockFeaturedCollections: [Collection] = []
    var mockUserCollections: [Collection] = []
    var shouldFail = false
    var delay: TimeInterval = 0.1

    func fetchFeaturedCollections() -> AnyPublisher<[Collection], Error> {
        if shouldFail {
            return Fail(error: CollectionsServiceError.serviceUnavailable)
                .eraseToAnyPublisher()
        }

        return Just(mockFeaturedCollections)
            .delay(for: .seconds(delay), scheduler: DispatchQueue.main)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func fetchUserCollections() -> AnyPublisher<[Collection], Error> {
        if shouldFail {
            return Fail(error: CollectionsServiceError.serviceUnavailable)
                .eraseToAnyPublisher()
        }

        return Just(mockUserCollections)
            .delay(for: .seconds(delay), scheduler: DispatchQueue.main)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func fetchCollection(id: String) -> AnyPublisher<Collection?, Error> {
        if shouldFail {
            return Fail(error: CollectionsServiceError.serviceUnavailable)
                .eraseToAnyPublisher()
        }

        let collection = (mockFeaturedCollections + mockUserCollections).first { $0.id == id }
        return Just(collection)
            .delay(for: .seconds(delay), scheduler: DispatchQueue.main)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func createCollection(name: String, description: String) -> AnyPublisher<Collection, Error> {
        if shouldFail {
            return Fail(error: CollectionsServiceError.serviceUnavailable)
                .eraseToAnyPublisher()
        }

        let collection = Collection.userCollection(name: name, description: description)
        mockUserCollections.append(collection)

        return Just(collection)
            .delay(for: .seconds(delay), scheduler: DispatchQueue.main)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func updateCollection(_ collection: Collection) -> AnyPublisher<Collection, Error> {
        if shouldFail {
            return Fail(error: CollectionsServiceError.serviceUnavailable)
                .eraseToAnyPublisher()
        }

        if let index = mockUserCollections.firstIndex(where: { $0.id == collection.id }) {
            mockUserCollections[index] = collection
        }

        return Just(collection)
            .delay(for: .seconds(delay), scheduler: DispatchQueue.main)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func deleteCollection(id: String) -> AnyPublisher<Void, Error> {
        if shouldFail {
            return Fail(error: CollectionsServiceError.serviceUnavailable)
                .eraseToAnyPublisher()
        }

        mockUserCollections.removeAll { $0.id == id }

        return Just(())
            .delay(for: .seconds(delay), scheduler: DispatchQueue.main)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func addArticleToCollection(_ article: Article, collectionID: String) -> AnyPublisher<Collection, Error> {
        if shouldFail {
            return Fail(error: CollectionsServiceError.serviceUnavailable)
                .eraseToAnyPublisher()
        }

        guard let index = mockUserCollections.firstIndex(where: { $0.id == collectionID }) else {
            return Fail(error: CollectionsServiceError.collectionNotFound)
                .eraseToAnyPublisher()
        }

        let updatedCollection = mockUserCollections[index].withArticle(article)
        mockUserCollections[index] = updatedCollection

        return Just(updatedCollection)
            .delay(for: .seconds(delay), scheduler: DispatchQueue.main)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func removeArticleFromCollection(articleID: String, collectionID: String) -> AnyPublisher<Collection, Error> {
        if shouldFail {
            return Fail(error: CollectionsServiceError.serviceUnavailable)
                .eraseToAnyPublisher()
        }

        guard let index = mockUserCollections.firstIndex(where: { $0.id == collectionID }) else {
            return Fail(error: CollectionsServiceError.collectionNotFound)
                .eraseToAnyPublisher()
        }

        let updatedCollection = mockUserCollections[index].withoutArticle(articleID)
        mockUserCollections[index] = updatedCollection

        return Just(updatedCollection)
            .delay(for: .seconds(delay), scheduler: DispatchQueue.main)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func markArticleAsRead(articleID: String, collectionID: String) -> AnyPublisher<Collection, Error> {
        if shouldFail {
            return Fail(error: CollectionsServiceError.serviceUnavailable)
                .eraseToAnyPublisher()
        }

        guard let index = mockUserCollections.firstIndex(where: { $0.id == collectionID }) else {
            return Fail(error: CollectionsServiceError.collectionNotFound)
                .eraseToAnyPublisher()
        }

        let updatedCollection = mockUserCollections[index].markingArticleAsRead(articleID)
        mockUserCollections[index] = updatedCollection

        return Just(updatedCollection)
            .delay(for: .seconds(delay), scheduler: DispatchQueue.main)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}

// MARK: - Mock Data

extension MockCollectionsService {
    static func withSampleData() -> MockCollectionsService {
        let service = MockCollectionsService()
        service.mockFeaturedCollections = Collection.sampleFeatured
        service.mockUserCollections = Collection.sampleUser
        return service
    }
}

extension Collection {
    static var sampleFeatured: [Collection] {
        [
            Collection(
                id: "climate-sample",
                name: "Climate Crisis",
                description: "Understand the science and solutions",
                imageURL: nil,
                articles: Article.samples,
                articleCount: 5,
                readArticleIDs: ["1", "2"],
                collectionType: .featured,
                isPremium: false,
                createdAt: Date(),
                updatedAt: Date()
            ),
            Collection(
                id: "tech-sample",
                name: "AI & Technology",
                description: "Latest in artificial intelligence",
                imageURL: nil,
                articles: Article.samples,
                articleCount: 5,
                readArticleIDs: [],
                collectionType: .featured,
                isPremium: true,
                createdAt: Date(),
                updatedAt: Date()
            ),
        ]
    }

    static var sampleUser: [Collection] {
        [
            Collection.userCollection(
                id: "user-1",
                name: "Research Notes",
                description: "Articles for my project",
                articles: Article.samples
            ),
        ]
    }
}

extension Article {
    static var samples: [Article] {
        (1 ... 5).map { index in
            Article(
                id: "\(index)",
                title: "Sample Article \(index)",
                description: "This is a sample article description for testing purposes.",
                content: "Full content of the sample article goes here.",
                author: "John Doe",
                source: ArticleSource(id: "guardian", name: "The Guardian"),
                url: "https://example.com/article/\(index)",
                imageURL: nil,
                publishedAt: Date().addingTimeInterval(TimeInterval(-index * 3600)),
                category: .technology
            )
        }
    }
}
