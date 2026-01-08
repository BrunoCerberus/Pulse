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
                ArticleSummary.self,
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

    // MARK: - Article Summaries

    @MainActor
    func saveSummary(_ article: Article, summary: String) async throws {
        let context = modelContainer.mainContext
        let articleID = article.id

        let descriptor = FetchDescriptor<ArticleSummary>(
            predicate: #Predicate { $0.articleID == articleID }
        )
        if let existing = try context.fetch(descriptor).first {
            existing.summary = summary
            existing.generatedAt = Date()
        } else {
            let summaryModel = ArticleSummary(from: article, summary: summary)
            context.insert(summaryModel)
        }
        try context.save()
    }

    @MainActor
    func fetchAllSummaries() async throws -> [(article: Article, summary: String, generatedAt: Date)] {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<ArticleSummary>(
            sortBy: [SortDescriptor(\.generatedAt, order: .reverse)]
        )
        let summaries = try context.fetch(descriptor)
        return summaries.map { ($0.toArticle(), $0.summary, $0.generatedAt) }
    }

    @MainActor
    func deleteSummary(articleID: String) async throws {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<ArticleSummary>(
            predicate: #Predicate { $0.articleID == articleID }
        )
        if let existing = try context.fetch(descriptor).first {
            context.delete(existing)
            try context.save()
        }
    }

    @MainActor
    func hasSummary(_ articleID: String) async -> Bool {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<ArticleSummary>(
            predicate: #Predicate { $0.articleID == articleID }
        )
        return (try? context.fetchCount(descriptor)) ?? 0 > 0
    }
}
