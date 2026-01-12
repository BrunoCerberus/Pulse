import Combine
import Foundation
import SwiftData

final class LiveStorageService: StorageService {
    private let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([
                BookmarkedArticle.self,
                ReadingHistoryEntry.self,
                UserPreferencesModel.self,
                CollectionModel.self,
                CollectionArticleModel.self,
            ])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    @MainActor
    func saveArticle(_ article: Article) async throws {
        let context = modelContainer.mainContext
        let bookmarked = BookmarkedArticle(from: article)
        context.insert(bookmarked)
        try context.save()
    }

    @MainActor
    func deleteArticle(_ article: Article) async throws {
        let context = modelContainer.mainContext
        let articleID = article.id
        let descriptor = FetchDescriptor<BookmarkedArticle>(
            predicate: #Predicate { $0.articleID == articleID }
        )
        if let existing = try context.fetch(descriptor).first {
            context.delete(existing)
            try context.save()
        }
    }

    @MainActor
    func fetchBookmarkedArticles() async throws -> [Article] {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<BookmarkedArticle>(
            sortBy: [SortDescriptor(\.savedAt, order: .reverse)]
        )
        let bookmarked = try context.fetch(descriptor)
        return bookmarked.map { $0.toArticle() }
    }

    @MainActor
    func isBookmarked(_ articleID: String) async -> Bool {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<BookmarkedArticle>(
            predicate: #Predicate { $0.articleID == articleID }
        )
        return (try? context.fetchCount(descriptor)) ?? 0 > 0
    }

    @MainActor
    func saveReadingHistory(_ article: Article) async throws {
        let context = modelContainer.mainContext
        let articleID = article.id
        let descriptor = FetchDescriptor<ReadingHistoryEntry>(
            predicate: #Predicate { $0.articleID == articleID }
        )
        if let existing = try context.fetch(descriptor).first {
            existing.readAt = Date()
        } else {
            let entry = ReadingHistoryEntry(from: article)
            context.insert(entry)
        }
        try context.save()
    }

    @MainActor
    func fetchReadingHistory() async throws -> [Article] {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<ReadingHistoryEntry>(
            sortBy: [SortDescriptor(\.readAt, order: .reverse)]
        )
        let history = try context.fetch(descriptor)
        return history.map { $0.toArticle() }
    }

    @MainActor
    func clearReadingHistory() async throws {
        let context = modelContainer.mainContext
        try context.delete(model: ReadingHistoryEntry.self)
        try context.save()
    }

    @MainActor
    func saveUserPreferences(_ preferences: UserPreferences) async throws {
        let context = modelContainer.mainContext
        try context.delete(model: UserPreferencesModel.self)
        let model = UserPreferencesModel(from: preferences)
        context.insert(model)
        try context.save()
    }

    @MainActor
    func fetchUserPreferences() async throws -> UserPreferences? {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<UserPreferencesModel>()
        return try context.fetch(descriptor).first?.toPreferences()
    }

    // MARK: - Collections

    @MainActor
    func saveCollection(_ collection: Collection) async throws {
        let context = modelContainer.mainContext
        let collectionID = collection.id

        let descriptor = FetchDescriptor<CollectionModel>(
            predicate: #Predicate { $0.collectionID == collectionID }
        )

        if let existing = try context.fetch(descriptor).first {
            existing.update(from: collection)
        } else {
            let model = CollectionModel(from: collection)
            context.insert(model)
        }
        try context.save()
    }

    @MainActor
    func deleteCollection(id: String) async throws {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<CollectionModel>(
            predicate: #Predicate { $0.collectionID == id }
        )
        if let existing = try context.fetch(descriptor).first {
            context.delete(existing)
            try context.save()
        }
    }

    @MainActor
    func fetchUserCollections() async throws -> [Collection] {
        let context = modelContainer.mainContext
        let userTypeRaw = CollectionType.user.rawValue
        let descriptor = FetchDescriptor<CollectionModel>(
            predicate: #Predicate { $0.collectionTypeRaw == userTypeRaw },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        let models = try context.fetch(descriptor)

        // Hydrate each collection with its stored articles
        return try models.map { model in
            let articles = try fetchCollectionArticlesSync(collectionID: model.collectionID, context: context)
            return model.toCollection(articles: articles)
        }
    }

    @MainActor
    func fetchCollection(id: String) async throws -> Collection? {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<CollectionModel>(
            predicate: #Predicate { $0.collectionID == id }
        )
        guard let model = try context.fetch(descriptor).first else {
            return nil
        }
        // Hydrate collection with stored articles
        let articles = try fetchCollectionArticlesSync(collectionID: id, context: context)
        return model.toCollection(articles: articles)
    }

    // MARK: - Collection Articles

    @MainActor
    func saveCollectionArticle(_ article: Article, collectionID: String, orderIndex: Int) async throws {
        let context = modelContainer.mainContext
        let compositeKey = "\(collectionID)_\(article.id)"

        let descriptor = FetchDescriptor<CollectionArticleModel>(
            predicate: #Predicate { $0.compositeKey == compositeKey }
        )

        // Only insert if not already exists
        if try context.fetch(descriptor).first == nil {
            let model = CollectionArticleModel(collectionID: collectionID, article: article, orderIndex: orderIndex)
            context.insert(model)
            try context.save()
        }
    }

    @MainActor
    func deleteCollectionArticle(articleID: String, collectionID: String) async throws {
        let context = modelContainer.mainContext
        let compositeKey = "\(collectionID)_\(articleID)"

        let descriptor = FetchDescriptor<CollectionArticleModel>(
            predicate: #Predicate { $0.compositeKey == compositeKey }
        )

        if let existing = try context.fetch(descriptor).first {
            context.delete(existing)
            try context.save()
        }
    }

    @MainActor
    func fetchCollectionArticles(collectionID: String) async throws -> [Article] {
        let context = modelContainer.mainContext
        return try fetchCollectionArticlesSync(collectionID: collectionID, context: context)
    }

    @MainActor
    func fetchArticlesForIDs(_ articleIDs: [String]) async throws -> [Article] {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<CollectionArticleModel>(
            predicate: #Predicate { articleIDs.contains($0.articleID) },
            sortBy: [SortDescriptor(\.orderIndex)]
        )
        let models = try context.fetch(descriptor)
        return models.map { $0.toArticle() }
    }

    // MARK: - Private Helpers

    @MainActor
    private func fetchCollectionArticlesSync(collectionID: String, context: ModelContext) throws -> [Article] {
        let descriptor = FetchDescriptor<CollectionArticleModel>(
            predicate: #Predicate { $0.collectionID == collectionID },
            sortBy: [SortDescriptor(\.orderIndex)]
        )
        let models = try context.fetch(descriptor)
        return models.map { $0.toArticle() }
    }
}
