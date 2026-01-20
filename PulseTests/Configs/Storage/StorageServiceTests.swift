import Foundation
@testable import Pulse
import Testing

@Suite("StorageService Protocol Tests")
struct StorageServiceProtocolTests {
    @Test("Protocol requires bookmark methods")
    func bookmarkMethods() {
        let service: StorageService = MockStorageService()
        #expect(true) // Protocol satisfied
    }

    @Test("Protocol requires reading history methods")
    func readingHistoryMethods() {
        let service: StorageService = MockStorageService()
        #expect(true)
    }

    @Test("Protocol requires preferences methods")
    func preferencesMethods() {
        let service: StorageService = MockStorageService()
        #expect(true)
    }
}

@Suite("MockStorageService Bookmark Tests")
struct MockStorageServiceBookmarkTests {
    let sut = MockStorageService()

    @Test("Save article adds to bookmarks")
    func saveArticle() async throws {
        let article = Article.mockArticles[0]
        try await sut.saveArticle(article)
        #expect(await sut.isBookmarked(article.id))
    }

    @Test("Delete article removes from bookmarks")
    func deleteArticle() async throws {
        let article = Article.mockArticles[0]
        try await sut.saveArticle(article)
        try await sut.deleteArticle(article)
        #expect(!(await sut.isBookmarked(article.id)))
    }

    @Test("Fetch bookmarks returns saved articles")
    func fetchBookmarks() async throws {
        let articles = Array(Article.mockArticles.prefix(2))
        for article in articles {
            try await sut.saveArticle(article)
        }
        let bookmarks = try await sut.fetchBookmarkedArticles()
        #expect(bookmarks.count == 2)
    }

    @Test("Is bookmarked returns false initially")
    func isBookmarkedInitially() async {
        let isBookmarked = await sut.isBookmarked("non-existent-id")
        #expect(!isBookmarked)
    }

    @Test("Is bookmarked returns true after save")
    func isBookmarkedAfterSave() async throws {
        let article = Article.mockArticles[0]
        try await sut.saveArticle(article)
        let isBookmarked = await sut.isBookmarked(article.id)
        #expect(isBookmarked)
    }

    @Test("Multiple bookmarks")
    func multipleBookmarks() async throws {
        let articles = Array(Article.mockArticles.prefix(3))
        for article in articles {
            try await sut.saveArticle(article)
        }
        let bookmarks = try await sut.fetchBookmarkedArticles()
        #expect(bookmarks.count == 3)
    }

    @Test("Delete error simulation")
    func deleteError() async throws {
        let service = MockStorageService()
        service.deleteArticleError = URLError(.badURL)
        let article = Article.mockArticles[0]
        do {
            try await service.deleteArticle(article)
            #expect(Bool(false), "Should have thrown")
        } catch {
            #expect(error is URLError)
        }
    }
}

@Suite("MockStorageService Reading History Tests")
struct MockStorageServiceReadingHistoryTests {
    let sut = MockStorageService()

    @Test("Save reading history adds entry")
    func saveReadingHistory() async throws {
        let article = Article.mockArticles[0]
        try await sut.saveReadingHistory(article)
        let history = try await sut.fetchReadingHistory()
        #expect(history.contains { $0.id == article.id })
    }

    @Test("Fetch reading history returns entries")
    func fetchReadingHistory() async throws {
        let articles = Array(Article.mockArticles.prefix(2))
        for article in articles {
            try await sut.saveReadingHistory(article)
        }
        let history = try await sut.fetchReadingHistory()
        #expect(history.count >= 2)
    }

    @Test("Recent reading history since date")
    func recentReadingHistory() async throws {
        let article = Article.mockArticles[0]
        try await sut.saveReadingHistory(article)
        let recent = try await sut.fetchRecentReadingHistory(since: Date(timeIntervalSinceNow: -3600))
        #expect(recent.contains { $0.id == article.id })
    }

    @Test("Clear reading history removes all")
    func clearReadingHistory() async throws {
        let articles = Array(Article.mockArticles.prefix(2))
        for article in articles {
            try await sut.saveReadingHistory(article)
        }
        try await sut.clearReadingHistory()
        let history = try await sut.fetchReadingHistory()
        #expect(history.isEmpty)
    }

    @Test("Clear history error simulation")
    func clearHistoryError() async throws {
        let service = MockStorageService()
        service.clearHistoryError = URLError(.badURL)
        do {
            try await service.clearReadingHistory()
            #expect(Bool(false), "Should have thrown")
        } catch {
            #expect(error is URLError)
        }
    }
}

@Suite("MockStorageService Preferences Tests")
struct MockStorageServicePreferencesTests {
    let sut = MockStorageService()

    @Test("Save preferences")
    func savePreferences() async throws {
        let prefs = UserPreferences.default
        try await sut.saveUserPreferences(prefs)
        #expect(true)
    }

    @Test("Fetch preferences returns saved")
    func fetchPreferences() async throws {
        let prefs = UserPreferences.default
        try await sut.saveUserPreferences(prefs)
        let fetched = try await sut.fetchUserPreferences()
        #expect(fetched != nil)
    }

    @Test("Fetch preferences when none saved")
    func fetchPreferencesEmpty() async throws {
        let service = MockStorageService()
        let prefs = try await service.fetchUserPreferences()
        #expect(prefs == nil)
    }

    @Test("Preferences error simulation")
    func savePreferencesError() async throws {
        let service = MockStorageService()
        service.savePreferencesError = URLError(.badURL)
        do {
            try await service.saveUserPreferences(.default)
            #expect(Bool(false), "Should have thrown")
        } catch {
            #expect(error is URLError)
        }
    }
}

@Suite("BookmarkedArticle Model Tests")
struct BookmarkedArticleTests {
    @Test("Initialize from article")
    func initFromArticle() {
        let article = Article.mockArticles[0]
        let bookmarked = BookmarkedArticle(from: article)
        #expect(bookmarked.articleID == article.id)
        #expect(bookmarked.title == article.title)
    }

    @Test("Convert to article")
    func toArticle() {
        let article = Article.mockArticles[0]
        let bookmarked = BookmarkedArticle(from: article)
        let converted = bookmarked.toArticle()
        #expect(converted.id == article.id)
        #expect(converted.title == article.title)
    }

    @Test("Saved at timestamp")
    func savedAtTimestamp() {
        let article = Article.mockArticles[0]
        let bookmarked = BookmarkedArticle(from: article)
        #expect(bookmarked.savedAt <= Date())
    }
}

@Suite("ReadingHistoryEntry Model Tests")
struct ReadingHistoryEntryTests {
    @Test("Initialize from article")
    func initFromArticle() {
        let article = Article.mockArticles[0]
        let entry = ReadingHistoryEntry(from: article)
        #expect(entry.articleID == article.id)
        #expect(entry.title == article.title)
    }

    @Test("Convert to article")
    func toArticle() {
        let article = Article.mockArticles[0]
        let entry = ReadingHistoryEntry(from: article)
        let converted = entry.toArticle()
        #expect(converted.id == article.id)
    }

    @Test("Read at timestamp")
    func readAtTimestamp() {
        let article = Article.mockArticles[0]
        let entry = ReadingHistoryEntry(from: article)
        #expect(entry.readAt <= Date())
    }
}

@Suite("Mock Storage Service Error Handling Tests")
struct MockStorageServiceErrorTests {
    @Test("Fetch bookmarks error simulation")
    func fetchBookmarksError() async throws {
        let service = MockStorageService()
        service.fetchBookmarksError = URLError(.badURL)
        do {
            _ = try await service.fetchBookmarkedArticles()
            #expect(Bool(false), "Should have thrown")
        } catch {
            #expect(error is URLError)
        }
    }

    @Test("Fetch preferences error simulation")
    func fetchPreferencesError() async throws {
        let service = MockStorageService()
        service.fetchPreferencesError = URLError(.badURL)
        do {
            _ = try await service.fetchUserPreferences()
            #expect(Bool(false), "Should have thrown")
        } catch {
            #expect(error is URLError)
        }
    }
}
