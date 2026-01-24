import Combine
import Foundation

/// Protocol defining the interface for local data persistence.
///
/// This protocol abstracts the storage layer and provides async/await operations
/// for managing bookmarks, reading history, and user preferences.
///
/// The default implementation (`LiveStorageService`) uses SwiftData for persistence,
/// enabling offline access to bookmarked articles and reading history.
///
/// ## Thread Safety
/// All operations are designed to be called from any actor context.
/// The implementation handles thread-safe access to the underlying data store.
protocol StorageService {
    // MARK: - Bookmarks

    /// Saves an article to the user's bookmarks for offline reading.
    /// - Parameter article: The article to bookmark.
    /// - Throws: Storage errors if the save operation fails.
    func saveArticle(_ article: Article) async throws

    /// Removes an article from the user's bookmarks.
    /// - Parameter article: The article to remove.
    /// - Throws: Storage errors if the delete operation fails.
    func deleteArticle(_ article: Article) async throws

    /// Fetches all bookmarked articles.
    /// - Returns: An array of bookmarked articles, ordered by bookmark date (newest first).
    /// - Throws: Storage errors if the fetch operation fails.
    func fetchBookmarkedArticles() async throws -> [Article]

    /// Checks if an article is bookmarked.
    /// - Parameter articleID: The unique identifier of the article.
    /// - Returns: `true` if the article is bookmarked, `false` otherwise.
    func isBookmarked(_ articleID: String) async -> Bool

    // MARK: - Reading History

    /// Records an article in the user's reading history.
    /// - Parameter article: The article that was read.
    /// - Throws: Storage errors if the save operation fails.
    func saveReadingHistory(_ article: Article) async throws

    /// Fetches the complete reading history.
    /// - Returns: An array of read articles, ordered by read date (newest first).
    /// - Throws: Storage errors if the fetch operation fails.
    func fetchReadingHistory() async throws -> [Article]

    /// Fetches reading history since a specific date.
    ///
    /// This is used by the AI Daily Digest feature to summarize recently read articles.
    /// - Parameter cutoffDate: The earliest date to include in the history.
    /// - Returns: Articles read since the cutoff date.
    /// - Throws: Storage errors if the fetch operation fails.
    func fetchRecentReadingHistory(since cutoffDate: Date) async throws -> [Article]

    /// Clears all reading history.
    ///
    /// This permanently deletes all reading history records. The operation cannot be undone.
    /// - Throws: Storage errors if the clear operation fails.
    func clearReadingHistory() async throws

    // MARK: - User Preferences

    /// Saves the user's preferences.
    /// - Parameter preferences: The preferences to persist.
    /// - Throws: Storage errors if the save operation fails.
    func saveUserPreferences(_ preferences: UserPreferences) async throws

    /// Fetches the user's preferences.
    /// - Returns: The stored preferences, or `nil` if none exist.
    /// - Throws: Storage errors if the fetch operation fails.
    func fetchUserPreferences() async throws -> UserPreferences?
}
