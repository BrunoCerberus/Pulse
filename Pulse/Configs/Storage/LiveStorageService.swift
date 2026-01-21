import Combine
import Foundation
import SwiftData

// MARK: - Background Storage Actor

/// Actor for performing SwiftData operations off the main thread.
/// Uses @ModelActor for automatic context management with SwiftData.
@ModelActor
actor BackgroundStorageActor {
    private let logCategory = "BackgroundStorage"

    /// Saves or updates reading history for an article.
    /// Runs on a background context to avoid main thread blocking.
    ///
    /// - Note: Callers typically use `try?` since reading history is non-critical data.
    ///   Errors are logged here for debugging purposes even when callers ignore them.
    func saveReadingHistory(_ article: Article) throws {
        let articleID = article.id
        let descriptor = FetchDescriptor<ReadingHistoryEntry>(
            predicate: #Predicate { $0.articleID == articleID }
        )

        do {
            if let existing = try modelContext.fetch(descriptor).first {
                existing.readAt = Date()
            } else {
                let entry = ReadingHistoryEntry(from: article)
                modelContext.insert(entry)
            }
            try modelContext.save()
        } catch {
            // Log error for debugging - callers may silently ignore with try?
            // but we want visibility into storage failures
            Logger.shared.error(
                "Failed to save reading history for article \(articleID): \(error.localizedDescription)",
                category: logCategory
            )
            throw error
        }
    }
}

// MARK: - Live Storage Service

final class LiveStorageService: StorageService {
    private let modelContainer: ModelContainer
    /// Background actor for off-main-thread SwiftData operations.
    /// Immutable after init to prevent race conditions.
    private let backgroundActor: BackgroundStorageActor

    init() {
        do {
            let schema = Schema([
                BookmarkedArticle.self,
                ReadingHistoryEntry.self,
                UserPreferencesModel.self,
            ])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            modelContainer = container
            // Initialize background actor with the same container
            backgroundActor = BackgroundStorageActor(modelContainer: container)
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

    /// Saves reading history using a background actor to avoid main thread blocking.
    /// This is called frequently during article browsing, so background execution
    /// prevents cumulative UI thread work.
    func saveReadingHistory(_ article: Article) async throws {
        try await backgroundActor.saveReadingHistory(article)
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
