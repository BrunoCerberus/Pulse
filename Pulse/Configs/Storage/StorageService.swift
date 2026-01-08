import Combine
import Foundation

protocol StorageService {
    func saveArticle(_ article: Article) async throws
    func deleteArticle(_ article: Article) async throws
    func fetchBookmarkedArticles() async throws -> [Article]
    func isBookmarked(_ articleID: String) async -> Bool
    func saveReadingHistory(_ article: Article) async throws
    func fetchReadingHistory() async throws -> [Article]
    func clearReadingHistory() async throws
    func saveUserPreferences(_ preferences: UserPreferences) async throws
    func fetchUserPreferences() async throws -> UserPreferences?

    // MARK: - Article Summaries

    func saveSummary(_ article: Article, summary: String) async throws
    func fetchAllSummaries() async throws -> [(article: Article, summary: String, generatedAt: Date)]
    func deleteSummary(articleID: String) async throws
    func hasSummary(_ articleID: String) async -> Bool
}
