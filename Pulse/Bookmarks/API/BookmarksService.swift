import Combine
import Foundation

protocol BookmarksService {
    func fetchBookmarks() -> AnyPublisher<[Article], Error>
    func removeBookmark(_ article: Article) -> AnyPublisher<Void, Error>
}
