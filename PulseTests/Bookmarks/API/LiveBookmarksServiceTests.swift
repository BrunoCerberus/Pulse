import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("LiveBookmarksService Tests")
struct LiveBookmarksServiceTests {
    let mockStorageService: MockStorageService

    init() {
        mockStorageService = MockStorageService()
    }

    private func createSUT() -> LiveBookmarksService {
        LiveBookmarksService(storageService: mockStorageService)
    }

    // MARK: - Fetch Bookmarks Tests

    @Test("fetchBookmarks returns bookmarked articles")
    func fetchBookmarksSuccess() async throws {
        mockStorageService.bookmarkedArticles = Article.mockArticles
        let sut = createSUT()

        var cancellables = Set<AnyCancellable>()
        var receivedArticles: [Article]?
        var receivedError: Error?

        let expectation = await withCheckedContinuation { continuation in
            sut.fetchBookmarks()
                .sink(
                    receiveCompletion: { completion in
                        if case let .failure(error) = completion {
                            receivedError = error
                        }
                        continuation.resume(returning: ())
                    },
                    receiveValue: { articles in
                        receivedArticles = articles
                    }
                )
                .store(in: &cancellables)
        }

        #expect(receivedError == nil)
        #expect(receivedArticles?.count == Article.mockArticles.count)
        #expect(receivedArticles?.first?.id == Article.mockArticles.first?.id)
    }

    @Test("fetchBookmarks returns empty array when no bookmarks")
    func fetchBookmarksEmpty() async throws {
        mockStorageService.bookmarkedArticles = []
        let sut = createSUT()

        var cancellables = Set<AnyCancellable>()
        var receivedArticles: [Article]?

        await withCheckedContinuation { continuation in
            sut.fetchBookmarks()
                .sink(
                    receiveCompletion: { _ in
                        continuation.resume(returning: ())
                    },
                    receiveValue: { articles in
                        receivedArticles = articles
                    }
                )
                .store(in: &cancellables)
        }

        #expect(receivedArticles?.isEmpty == true)
    }

    @Test("fetchBookmarks propagates storage errors")
    func fetchBookmarksError() async throws {
        let testError = NSError(domain: "test", code: 1, userInfo: nil)
        mockStorageService.fetchBookmarksError = testError
        let sut = createSUT()

        var cancellables = Set<AnyCancellable>()
        var receivedError: Error?

        await withCheckedContinuation { continuation in
            sut.fetchBookmarks()
                .sink(
                    receiveCompletion: { completion in
                        if case let .failure(error) = completion {
                            receivedError = error
                        }
                        continuation.resume(returning: ())
                    },
                    receiveValue: { _ in }
                )
                .store(in: &cancellables)
        }

        #expect(receivedError != nil)
    }

    // MARK: - Remove Bookmark Tests

    @Test("removeBookmark removes article from storage")
    func removeBookmarkSuccess() async throws {
        let articleToRemove = Article.mockArticles[0]
        mockStorageService.bookmarkedArticles = [articleToRemove]
        let sut = createSUT()

        var cancellables = Set<AnyCancellable>()
        var completedSuccessfully = false
        var receivedError: Error?

        await withCheckedContinuation { continuation in
            sut.removeBookmark(articleToRemove)
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            completedSuccessfully = true
                        case let .failure(error):
                            receivedError = error
                        }
                        continuation.resume(returning: ())
                    },
                    receiveValue: { _ in }
                )
                .store(in: &cancellables)
        }

        #expect(completedSuccessfully)
        #expect(receivedError == nil)

        // Verify the article was removed from storage
        let isStillBookmarked = await mockStorageService.isBookmarked(articleToRemove.id)
        #expect(isStillBookmarked == false)
    }

    @Test("removeBookmark propagates storage errors")
    func removeBookmarkError() async throws {
        let testError = NSError(domain: "test", code: 1, userInfo: nil)
        mockStorageService.deleteArticleError = testError
        let sut = createSUT()

        var cancellables = Set<AnyCancellable>()
        var receivedError: Error?

        await withCheckedContinuation { continuation in
            sut.removeBookmark(Article.mockArticles[0])
                .sink(
                    receiveCompletion: { completion in
                        if case let .failure(error) = completion {
                            receivedError = error
                        }
                        continuation.resume(returning: ())
                    },
                    receiveValue: { _ in }
                )
                .store(in: &cancellables)
        }

        #expect(receivedError != nil)
    }
}
