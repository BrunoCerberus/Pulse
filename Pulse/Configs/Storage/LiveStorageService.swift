import Combine
import Foundation
import SwiftData

// MARK: - Background Storage Actor

/// Actor for performing SwiftData operations off the main thread.
/// Uses @ModelActor for automatic context management with SwiftData.
@ModelActor
actor BackgroundStorageActor {
    /// Saves or updates reading history for an article.
    /// Runs on a background context to avoid main thread blocking.
    func saveReadingHistory(_ article: Article) throws {
        let articleID = article.id
        let descriptor = FetchDescriptor<ReadingHistoryEntry>(
            predicate: #Predicate { $0.articleID == articleID }
        )

        if let existing = try modelContext.fetch(descriptor).first {
            existing.readAt = Date()
        } else {
            let entry = ReadingHistoryEntry(from: article)
            modelContext.insert(entry)
        }
        try modelContext.save()
    }
}

// MARK: - Live Storage Service

final class LiveStorageService: StorageService {
    private let modelContainer: ModelContainer
    private var backgroundActor: BackgroundStorageActor?

    init() {
        do {
            let schema = Schema([
                BookmarkedArticle.self,
                ReadingHistoryEntry.self,
                UserPreferencesModel.self,
            ])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            // Initialize background actor with the same container
            backgroundActor = BackgroundStorageActor(modelContainer: modelContainer)
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
        guard let actor = backgroundActor else {
            // Fallback to main context if background actor initialization failed
            try await saveReadingHistoryOnMain(article)
            return
        }
        try await actor.saveReadingHistory(article)
    }

    /// Fallback method for saving reading history on MainActor
    @MainActor
    private func saveReadingHistoryOnMain(_ article: Article) throws {
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
