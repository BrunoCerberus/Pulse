import Foundation
import SwiftData

@Model
final class CollectionModel {
    @Attribute(.unique) var collectionID: String
    var name: String
    var collectionDescription: String
    var imageURL: String?
    var articleIDs: [String]
    var readArticleIDs: [String]
    var collectionTypeRaw: String
    var isPremium: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        collectionID: String,
        name: String,
        collectionDescription: String,
        imageURL: String? = nil,
        articleIDs: [String] = [],
        readArticleIDs: [String] = [],
        collectionTypeRaw: String = CollectionType.user.rawValue,
        isPremium: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.collectionID = collectionID
        self.name = name
        self.collectionDescription = collectionDescription
        self.imageURL = imageURL
        self.articleIDs = articleIDs
        self.readArticleIDs = readArticleIDs
        self.collectionTypeRaw = collectionTypeRaw
        self.isPremium = isPremium
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    convenience init(from collection: Collection) {
        self.init(
            collectionID: collection.id,
            name: collection.name,
            collectionDescription: collection.description,
            imageURL: collection.imageURL,
            articleIDs: collection.articles.map(\.id),
            readArticleIDs: Array(collection.readArticleIDs),
            collectionTypeRaw: collection.collectionType.rawValue,
            isPremium: collection.isPremium,
            createdAt: collection.createdAt,
            updatedAt: collection.updatedAt
        )
    }

    func toCollection(articles: [Article]) -> Collection {
        Collection(
            id: collectionID,
            name: name,
            description: collectionDescription,
            imageURL: imageURL,
            articles: articles,
            articleCount: articleIDs.count,
            readArticleIDs: Set(readArticleIDs),
            collectionType: CollectionType(rawValue: collectionTypeRaw) ?? .user,
            isPremium: isPremium,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    func update(from collection: Collection) {
        name = collection.name
        collectionDescription = collection.description
        imageURL = collection.imageURL
        // Only update articleIDs if collection has hydrated articles,
        // or if explicitly clearing (articleCount == 0).
        // This preserves stored IDs when collection is loaded without articles.
        if !collection.articles.isEmpty {
            articleIDs = collection.articles.map(\.id)
        } else if collection.articleCount == 0 {
            articleIDs = []
        }
        // Always preserve articleCount > 0 with empty articles (non-hydrated state)
        readArticleIDs = Array(collection.readArticleIDs)
        collectionTypeRaw = collection.collectionType.rawValue
        isPremium = collection.isPremium
        updatedAt = Date()
    }
}
