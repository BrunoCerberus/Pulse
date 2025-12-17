import Foundation
import Combine

protocol BookmarksService {
    func fetchBookmarks() -> AnyPublisher<[Article], Error>
    func removeBookmark(_ article: Article) -> AnyPublisher<Void, Error>
}

final class LiveBookmarksService: BookmarksService {
    private let storageService: StorageService

    init(storageService: StorageService = ServiceLocator.shared.resolve(StorageService.self)) {
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
