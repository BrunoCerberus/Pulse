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

    /// Saves reading history on MainActor to ensure SwiftData thread safety.
    /// The operation is lightweight (single record upsert) and won't noticeably block UI.
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
    func fetchRecentReadingHistory(since cutoffDate: Date) async throws -> [Article] {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<ReadingHistoryEntry>(
            predicate: #Predicate { $0.readAt > cutoffDate },
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
}
