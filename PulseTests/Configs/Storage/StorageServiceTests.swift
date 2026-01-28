import Foundation
@testable import Pulse
import Testing

@Suite("StorageService Protocol Tests")
struct StorageServiceProtocolTests {
    @Test("MockStorageService conforms to StorageService")
    func mockConformsToProtocol() {
        let mock = MockStorageService()
        let _: StorageService = mock
        // If this compiles, the mock conforms to the protocol
        #expect(true)
    }

    @Test("MockStorageService can save and fetch bookmarks")
    func mockSaveAndFetchBookmarks() async throws {
        let mock = MockStorageService()
        let article = Article.mockArticles[0]

        try await mock.saveArticle(article)
        let bookmarks = try await mock.fetchBookmarkedArticles()

        #expect(bookmarks.count == 1)
        #expect(bookmarks.first?.id == article.id)
    }

    @Test("MockStorageService isBookmarked works correctly")
    func mockIsBookmarked() async throws {
        let mock = MockStorageService()
        let article = Article.mockArticles[0]

        let isBookmarkedBefore = await mock.isBookmarked(article.id)
        #expect(isBookmarkedBefore == false)

        try await mock.saveArticle(article)

        let isBookmarkedAfter = await mock.isBookmarked(article.id)
        #expect(isBookmarkedAfter == true)
    }

    @Test("MockStorageService can delete bookmarks")
    func mockDeleteBookmark() async throws {
        let mock = MockStorageService()
        let article = Article.mockArticles[0]

        try await mock.saveArticle(article)
        try await mock.deleteArticle(article)

        let bookmarks = try await mock.fetchBookmarkedArticles()
        #expect(bookmarks.isEmpty)
    }

    @Test("MockStorageService can save and fetch reading history")
    func mockSaveAndFetchHistory() async throws {
        let mock = MockStorageService()
        let article = Article.mockArticles[0]

        try await mock.saveReadingHistory(article)
        let history = try await mock.fetchReadingHistory()

        #expect(history.count == 1)
        #expect(history.first?.id == article.id)
    }

    @Test("MockStorageService can clear reading history")
    func mockClearHistory() async throws {
        let mock = MockStorageService()
        let article = Article.mockArticles[0]

        try await mock.saveReadingHistory(article)
        try await mock.clearReadingHistory()

        let history = try await mock.fetchReadingHistory()
        #expect(history.isEmpty)
    }

    @Test("MockStorageService can save and fetch user preferences")
    func mockSaveAndFetchPreferences() async throws {
        let mock = MockStorageService()
        var prefs = UserPreferences.default
        prefs.notificationsEnabled = true

        try await mock.saveUserPreferences(prefs)
        let fetched = try await mock.fetchUserPreferences()

        #expect(fetched?.notificationsEnabled == true)
    }

    @Test("MockStorageService error simulation works")
    func mockErrorSimulation() async {
        let mock = MockStorageService()
        mock.fetchBookmarksError = NSError(domain: "test", code: 1)

        do {
            _ = try await mock.fetchBookmarkedArticles()
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(true)
        }
    }
}
