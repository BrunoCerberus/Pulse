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

        // For user collections, we need to fetch the actual articles
        // Since we only store article IDs, we return collections with empty articles
        // The articles will be populated when viewing the collection detail
        return models.map { $0.toCollection(articles: []) }
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
        return model.toCollection(articles: [])
    }
}
