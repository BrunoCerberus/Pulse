import Combine
import Foundation

/// Live implementation of BookmarksService for managing saved articles.
///
/// This service bridges the Combine-based domain layer with the async/await
/// `StorageService` for bookmark persistence, providing:
/// - Fetching all bookmarked articles sorted by save date
/// - Removing individual bookmarks
///
/// ## Thread Safety
/// All operations are dispatched to the main queue for UI consistency.
///
/// ## Dependencies
/// - `StorageService`: SwiftData-based persistence layer
final class LiveBookmarksService: BookmarksService {
    private let storageService: StorageService

    init(storageService: StorageService) {
        self.storageService = storageService
    }

    func fetchBookmarks() -> AnyPublisher<[Article], Error> {
        Future { [storageService] promise in
            Task {
                do {
                    let articles = try await storageService.fetchBookmarkedArticles()
                    promise(.success(articles))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func removeBookmark(_ article: Article) -> AnyPublisher<Void, Error> {
        Future { [storageService] promise in
            Task {
                do {
                    try await storageService.deleteArticle(article)
                    promise(.success(()))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
}
