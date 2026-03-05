import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("BookmarksDomainInteractor Extended Tests")
@MainActor
struct BookmarksDomainInteractorExtendedTests {
    let mockBookmarksService: MockBookmarksService
    let mockAnalyticsService: MockAnalyticsService
    let serviceLocator: ServiceLocator
    let sut: BookmarksDomainInteractor

    init() {
        mockBookmarksService = MockBookmarksService()
        mockAnalyticsService = MockAnalyticsService()
        serviceLocator = ServiceLocator()

        serviceLocator.register(BookmarksService.self, instance: mockBookmarksService)
        serviceLocator.register(AnalyticsService.self, instance: mockAnalyticsService)

        sut = BookmarksDomainInteractor(serviceLocator: serviceLocator)
    }

    // MARK: - Share Article Tests

    @Test("Share article sets articleToShare")
    func shareArticleSetsState() async throws {
        let articles = Article.mockArticles
        mockBookmarksService.bookmarks = articles

        sut.dispatch(action: .loadBookmarks)
        try await Task.sleep(nanoseconds: 300_000_000)

        sut.dispatch(action: .shareArticle(articleId: articles[0].id))
        #expect(sut.currentState.articleToShare?.id == articles[0].id)
    }

    @Test("Share non-existent article does nothing")
    func shareNonExistentArticle() async throws {
        let articles = Article.mockArticles
        mockBookmarksService.bookmarks = articles

        sut.dispatch(action: .loadBookmarks)
        try await Task.sleep(nanoseconds: 300_000_000)

        sut.dispatch(action: .shareArticle(articleId: "non-existent"))
        #expect(sut.currentState.articleToShare == nil)
    }

    @Test("Clear article to share resets state")
    func clearArticleToShare() async throws {
        let articles = Article.mockArticles
        mockBookmarksService.bookmarks = articles

        sut.dispatch(action: .loadBookmarks)
        try await Task.sleep(nanoseconds: 300_000_000)

        sut.dispatch(action: .shareArticle(articleId: articles[0].id))
        #expect(sut.currentState.articleToShare != nil)

        sut.dispatch(action: .clearArticleToShare)
        #expect(sut.currentState.articleToShare == nil)
    }

    // MARK: - Analytics Tests

    @Test("Share article logs analytics event")
    func shareArticleLogsEvent() async throws {
        let articles = Article.mockArticles
        mockBookmarksService.bookmarks = articles

        sut.dispatch(action: .loadBookmarks)
        try await Task.sleep(nanoseconds: 300_000_000)

        sut.dispatch(action: .shareArticle(articleId: articles[0].id))

        let shareEvents = mockAnalyticsService.loggedEvents.filter { $0.name == "article_shared" }
        #expect(shareEvents.count == 1)
    }

    // MARK: - Multiple Operations

    @Test("Multiple remove bookmarks work correctly")
    func multipleRemoveBookmarks() async throws {
        mockBookmarksService.bookmarks = Article.mockArticles

        sut.dispatch(action: .loadBookmarks)
        try await Task.sleep(nanoseconds: 300_000_000)

        let initialCount = sut.currentState.bookmarks.count

        // Remove first two
        sut.dispatch(action: .removeBookmark(articleId: Article.mockArticles[0].id))
        try await Task.sleep(nanoseconds: 300_000_000)
        sut.dispatch(action: .removeBookmark(articleId: Article.mockArticles[1].id))
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.currentState.bookmarks.count == initialCount - 2)
    }

    @Test("Select then clear then select different article")
    func selectClearSelectDifferent() async throws {
        let articles = Article.mockArticles
        mockBookmarksService.bookmarks = articles

        sut.dispatch(action: .loadBookmarks)
        try await Task.sleep(nanoseconds: 300_000_000)

        sut.dispatch(action: .selectArticle(articleId: articles[0].id))
        try await Task.sleep(nanoseconds: 100_000_000)
        #expect(sut.currentState.selectedArticle?.id == articles[0].id)

        sut.dispatch(action: .clearSelectedArticle)
        #expect(sut.currentState.selectedArticle == nil)

        sut.dispatch(action: .selectArticle(articleId: articles[1].id))
        try await Task.sleep(nanoseconds: 100_000_000)
        #expect(sut.currentState.selectedArticle?.id == articles[1].id)
    }

    @Test("Refresh after load replaces bookmarks")
    func refreshAfterLoad() async throws {
        mockBookmarksService.bookmarks = Array(Article.mockArticles.prefix(2))
        sut.dispatch(action: .loadBookmarks)
        try await Task.sleep(nanoseconds: 300_000_000)
        #expect(sut.currentState.bookmarks.count == 2)

        mockBookmarksService.bookmarks = Article.mockArticles
        sut.dispatch(action: .refresh)
        try await Task.sleep(nanoseconds: 300_000_000)
        #expect(sut.currentState.bookmarks.count == Article.mockArticles.count)
    }
}
