import Combine
import Foundation

protocol StorageService {
    // MARK: - Bookmarks

    func saveArticle(_ article: Article) async throws
    func deleteArticle(_ article: Article) async throws
    func fetchBookmarkedArticles() async throws -> [Article]
    func isBookmarked(_ articleID: String) async -> Bool

    // MARK: - Reading History

    func saveReadingHistory(_ article: Article) async throws
    func fetchReadingHistory() async throws -> [Article]
    func fetchRecentReadingHistory(since cutoffDate: Date) async throws -> [Article]
    func clearReadingHistory() async throws

    // MARK: - User Preferences

    func saveUserPreferences(_ preferences: UserPreferences) async throws
    func fetchUserPreferences() async throws -> UserPreferences?
}
