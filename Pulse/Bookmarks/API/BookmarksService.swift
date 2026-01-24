import Combine
import Foundation

/// Protocol defining the interface for managing bookmarked articles.
///
/// This protocol provides operations for fetching and removing bookmarks.
/// Bookmarks are persisted locally using SwiftData for offline reading.
///
/// The default implementation (`LiveBookmarksService`) uses `StorageService`
/// for persistence.
///
/// - Note: Adding bookmarks is handled by `StorageService.saveArticle(_:)` directly.
protocol BookmarksService {
    /// Fetches all bookmarked articles.
    /// - Returns: Publisher emitting an array of bookmarked articles or an error.
    func fetchBookmarks() -> AnyPublisher<[Article], Error>

    /// Removes an article from bookmarks.
    /// - Parameter article: The article to remove from bookmarks.
    /// - Returns: Publisher that completes on success or emits an error.
    func removeBookmark(_ article: Article) -> AnyPublisher<Void, Error>
}
