import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("LiveBookmarksService Tests")
struct LiveBookmarksServiceTests {
    @Test("LiveBookmarksService can be instantiated")
    func canBeInstantiated() {
        let mockStorage = MockStorageService()
        let service = LiveBookmarksService(storageService: mockStorage)
        #expect(service is BookmarksService)
    }

    @Test("fetchBookmarks returns correct publisher type")
    func fetchBookmarksReturnsCorrectType() {
        let mockStorage = MockStorageService()
        let service = LiveBookmarksService(storageService: mockStorage)
        let publisher = service.fetchBookmarks()
        let typeCheck: AnyPublisher<[Article], Error> = publisher
        #expect(typeCheck is AnyPublisher<[Article], Error>)
    }

    @Test("removeBookmark returns correct publisher type")
    func removeBookmarkReturnsCorrectType() throws {
        let mockStorage = MockStorageService()
        let service = LiveBookmarksService(storageService: mockStorage)
        let article = try #require(Article.mockArticles.first)
        let publisher = service.removeBookmark(article)
        let typeCheck: AnyPublisher<Void, Error> = publisher
        #expect(typeCheck is AnyPublisher<Void, Error>)
    }
}
