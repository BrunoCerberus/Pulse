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

    // MARK: - User Preferences

    /// Saves the user's preferences.
    /// - Parameter preferences: The preferences to persist.
    /// - Throws: Storage errors if the save operation fails.
    func saveUserPreferences(_ preferences: UserPreferences) async throws

    /// Fetches the user's preferences.
    /// - Returns: The stored preferences, or `nil` if none exist.
    /// - Throws: Storage errors if the fetch operation fails.
    func fetchUserPreferences() async throws -> UserPreferences?

    // MARK: - Reading History

    /// Marks an article as read in the user's reading history.
    /// If the article was already read, updates the `readAt` timestamp.
    /// - Parameter article: The article to mark as read.
    /// - Throws: Storage errors if the save operation fails.
    func markArticleAsRead(_ article: Article) async throws

    /// Checks if an article has been read.
    /// - Parameter articleID: The unique identifier of the article.
    /// - Returns: `true` if the article has been read, `false` otherwise.
    func isRead(_ articleID: String) async -> Bool

    /// Fetches the IDs of all read articles.
    /// - Returns: A set of article IDs that have been read.
    /// - Throws: Storage errors if the fetch operation fails.
    func fetchReadArticleIDs() async throws -> Set<String>

    /// Fetches all read articles, ordered by read date (newest first).
    /// - Returns: An array of articles from reading history.
    /// - Throws: Storage errors if the fetch operation fails.
    func fetchReadArticles() async throws -> [Article]

    /// Clears all reading history.
    /// - Throws: Storage errors if the delete operation fails.
    func clearReadingHistory() async throws
}
