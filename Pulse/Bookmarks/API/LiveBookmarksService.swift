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
        let storageService = UncheckedSendableBox(value: storageService)
        return Future { promise in
            let promise = UncheckedSendableBox(value: promise)
            Task {
                do {
                    let articles = try await storageService.value.fetchBookmarkedArticles()
                    promise.value(.success(articles))
                } catch {
                    promise.value(.failure(error))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func removeBookmark(_ article: Article) -> AnyPublisher<Void, Error> {
        let storageService = UncheckedSendableBox(value: storageService)
        return Future { promise in
            let promise = UncheckedSendableBox(value: promise)
            Task {
                do {
                    try await storageService.value.deleteArticle(article)
                    promise.value(.success(()))
                } catch {
                    promise.value(.failure(error))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
}
