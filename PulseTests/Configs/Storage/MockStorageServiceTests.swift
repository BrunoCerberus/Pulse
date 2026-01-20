import Foundation
@testable import Pulse
import Testing

@Suite("MockStorageService Tests")
struct MockStorageServiceTests {
    var sut: MockStorageService

    init() {
        sut = MockStorageService()
    }

    @Test("Initial state is empty")
    func initialStateIsEmpty() {
        #expect(sut.bookmarkedArticles.isEmpty)
        #expect(sut.readingHistory.isEmpty)
        #expect(sut.userPreferences == nil)
    }

    @Test("Save article adds to bookmarks")
    func saveArticleAddsToBookmarks() async throws {
        let article = Article.mockArticles.first!

        try await sut.saveArticle(article)

        #expect(sut.bookmarkedArticles.count == 1)
        #expect(sut.bookmarkedArticles.first?.id == article.id)
    }

    @Test("Save multiple articles accumulates bookmarks")
    func saveMultipleArticlesAccumulates() async throws {
        let article1 = Article.mockArticles[0]
        let article2 = Article.mockArticles[1]

        try await sut.saveArticle(article1)
        try await sut.saveArticle(article2)

        #expect(sut.bookmarkedArticles.count == 2)
    }

    @Test("Delete article removes from bookmarks")
    func deleteArticleRemovesFromBookmarks() async throws {
        let article = Article.mockArticles.first!
        try await sut.saveArticle(article)
        #expect(sut.bookmarkedArticles.count == 1)

        try await sut.deleteArticle(article)

        #expect(sut.bookmarkedArticles.isEmpty)
    }

    @Test("Delete article error is propagated")
    func deleteArticleErrorIsPropagated() async throws {
        let article = Article.mockArticles.first!
        let mockError = NSError(domain: "Test", code: 1, userInfo: nil)
        sut.deleteArticleError = mockError

        do {
            try await sut.deleteArticle(article)
            Issue.record("Expected error was thrown")
        } catch {}
    }

    @Test("Fetch bookmarked articles returns saved articles")
    func fetchBookmarkedArticlesReturnsSaved() async throws {
        let article1 = Article.mockArticles[0]
        let article2 = Article.mockArticles[1]

        try await sut.saveArticle(article1)
        try await sut.saveArticle(article2)

        let articles = try await sut.fetchBookmarkedArticles()

        #expect(articles.count == 2)
    }

    @Test("Fetch bookmarks error is propagated")
    func fetchBookmarksErrorIsPropagated() async throws {
        let mockError = NSError(domain: "Test", code: 1, userInfo: nil)
        sut.fetchBookmarksError = mockError

        do {
            _ = try await sut.fetchBookmarkedArticles()
            Issue.record("Expected error was thrown")
        } catch {}
    }

    @Test("Is bookmarked returns true for bookmarked article")
    func isBookmarkedReturnsTrueForBookmarked() async throws {
        let article = Article.mockArticles.first!
        try await sut.saveArticle(article)

        let isBookmarked = await sut.isBookmarked(article.id)

        #expect(isBookmarked)
    }

    @Test("Is bookmarked returns false for non-bookmarked article")
    func isBookmarkedReturnsFalseForNonBookmarked() async {
        let isBookmarked = await sut.isBookmarked("non-existent-id")

        #expect(!isBookmarked)
    }

    @Test("Save reading history adds article")
    func saveReadingHistoryAddsArticle() async throws {
        let article = Article.mockArticles.first!

        try await sut.saveReadingHistory(article)

        #expect(sut.readingHistory.count == 1)
        #expect(sut.readingHistory.first?.id == article.id)
    }

    @Test("Save reading history updates existing article")
    func saveReadingHistoryUpdatesExisting() async throws {
        let article = Article.mockArticles.first!
        try await sut.saveReadingHistory(article)
        #expect(sut.readingHistory.count == 1)

        try await sut.saveReadingHistory(article)

        #expect(sut.readingHistory.count == 1)
    }

    @Test("Fetch reading history returns saved articles")
    func fetchReadingHistoryReturnsSaved() async throws {
        let article = Article.mockArticles.first!
        try await sut.saveReadingHistory(article)

        let history = try await sut.fetchReadingHistory()

        #expect(history.count == 1)
    }

    @Test("Fetch recent reading history returns articles")
    func fetchRecentReadingHistoryReturnsArticles() async throws {
        let article = Article.mockArticles.first!
        try await sut.saveReadingHistory(article)

        let history = try await sut.fetchRecentReadingHistory(since: Date().addingTimeInterval(-3600))

        #expect(history.count == 1)
    }

    @Test("Clear reading history removes all entries")
    func clearReadingHistoryRemovesAll() async throws {
        let article1 = Article.mockArticles[0]
        let article2 = Article.mockArticles[1]
        try await sut.saveReadingHistory(article1)
        try await sut.saveReadingHistory(article2)
        #expect(sut.readingHistory.count == 2)

        try await sut.clearReadingHistory()

        #expect(sut.readingHistory.isEmpty)
    }

    @Test("Clear reading history error is propagated")
    func clearHistoryErrorIsPropagated() async throws {
        let mockError = NSError(domain: "Test", code: 1, userInfo: nil)
        sut.clearHistoryError = mockError

        do {
            try await sut.clearReadingHistory()
            Issue.record("Expected error was thrown")
        } catch {}
    }

    @Test("Save user preferences stores preferences")
    func saveUserPreferencesStoresPreferences() async throws {
        let preferences = UserPreferences.default

        try await sut.saveUserPreferences(preferences)

        #expect(sut.userPreferences != nil)
    }

    @Test("Fetch user preferences returns stored preferences")
    func fetchUserPreferencesReturnsStored() async throws {
        let preferences = UserPreferences.default
        try await sut.saveUserPreferences(preferences)

        let fetched = try await sut.fetchUserPreferences()

        #expect(fetched != nil)
    }

    @Test("Fetch user preferences returns nil when not set")
    func fetchUserPreferencesReturnsNilWhenNotSet() async throws {
        let fetched = try await sut.fetchUserPreferences()

        #expect(fetched == nil)
    }

    @Test("Save preferences error is propagated")
    func savePreferencesErrorIsPropagated() async throws {
        let mockError = NSError(domain: "Test", code: 1, userInfo: nil)
        sut.savePreferencesError = mockError

        do {
            try await sut.saveUserPreferences(UserPreferences.default)
            Issue.record("Expected error was thrown")
        } catch {}
    }

    @Test("Fetch preferences error is propagated")
    func fetchPreferencesErrorIsPropagated() async throws {
        let mockError = NSError(domain: "Test", code: 1, userInfo: nil)
        sut.fetchPreferencesError = mockError

        do {
            _ = try await sut.fetchUserPreferences()
            Issue.record("Expected error was thrown")
        } catch {}
    }
}
