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
    async func testSaveArticle() throws {
        let article = Article.mockArticles[0]
        try await sut.saveArticle(article)
        #expect(await sut.isBookmarked(article.id))
    }

    @Test("Delete article removes from bookmarks")
    async func testDeleteArticle() throws {
        let article = Article.mockArticles[0]
        try await sut.saveArticle(article)
        try await sut.deleteArticle(article)
        #expect(!(await sut.isBookmarked(article.id)))
    }

    @Test("Fetch bookmarks returns saved articles")
    async func testFetchBookmarks() throws {
        let articles = Array(Article.mockArticles.prefix(2))
        for article in articles {
            try await sut.saveArticle(article)
        }
        let bookmarks = try await sut.fetchBookmarkedArticles()
        #expect(bookmarks.count == 2)
    }

    @Test("Is bookmarked returns false initially")
    async func testIsBookmarkedInitially() {
        let isBookmarked = await sut.isBookmarked("non-existent-id")
        #expect(!isBookmarked)
    }

    @Test("Is bookmarked returns true after save")
    async func testIsBookmarkedAfterSave() throws {
        let article = Article.mockArticles[0]
        try await sut.saveArticle(article)
        let isBookmarked = await sut.isBookmarked(article.id)
        #expect(isBookmarked)
    }

    @Test("Multiple bookmarks")
    async func testMultipleBookmarks() throws {
        let articles = Array(Article.mockArticles.prefix(3))
        for article in articles {
            try await sut.saveArticle(article)
        }
        let bookmarks = try await sut.fetchBookmarkedArticles()
        #expect(bookmarks.count == 3)
    }

    @Test("Delete error simulation")
    async func testDeleteError() async throws {
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
    async func testSaveReadingHistory() throws {
        let article = Article.mockArticles[0]
        try await sut.saveReadingHistory(article)
        let history = try await sut.fetchReadingHistory()
        #expect(history.contains { $0.id == article.id })
    }

    @Test("Fetch reading history returns entries")
    async func testFetchReadingHistory() throws {
        let articles = Array(Article.mockArticles.prefix(2))
        for article in articles {
            try await sut.saveReadingHistory(article)
        }
        let history = try await sut.fetchReadingHistory()
        #expect(history.count >= 2)
    }

    @Test("Recent reading history since date")
    async func testRecentReadingHistory() throws {
        let article = Article.mockArticles[0]
        try await sut.saveReadingHistory(article)
        let recent = try await sut.fetchRecentReadingHistory(since: Date(timeIntervalSinceNow: -3600))
        #expect(recent.contains { $0.id == article.id })
    }

    @Test("Clear reading history removes all")
    async func testClearReadingHistory() throws {
        let articles = Array(Article.mockArticles.prefix(2))
        for article in articles {
            try await sut.saveReadingHistory(article)
        }
        try await sut.clearReadingHistory()
        let history = try await sut.fetchReadingHistory()
        #expect(history.isEmpty)
    }

    @Test("Clear history error simulation")
    async func testClearHistoryError() async throws {
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
    async func testSavePreferences() throws {
        let prefs = UserPreferences.default
        try await sut.saveUserPreferences(prefs)
        #expect(true)
    }

    @Test("Fetch preferences returns saved")
    async func testFetchPreferences() throws {
        let prefs = UserPreferences.default
        try await sut.saveUserPreferences(prefs)
        let fetched = try await sut.fetchUserPreferences()
        #expect(fetched != nil)
    }

    @Test("Fetch preferences when none saved")
    async func testFetchPreferencesEmpty() throws {
        let service = MockStorageService()
        let prefs = try await service.fetchUserPreferences()
        #expect(prefs == nil)
    }

    @Test("Preferences error simulation")
    async func testSavePreferencesError() async throws {
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
    func testToArticle() {
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
    func testInitFromArticle() {
        let article = Article.mockArticles[0]
        let entry = ReadingHistoryEntry(from: article)
        #expect(entry.articleID == article.id)
        #expect(entry.title == article.title)
    }

    @Test("Convert to article")
    func testToArticle() {
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

@Suite("UserPreferencesModel Tests")
struct UserPreferencesModelTests {
    @Test("Initialize from UserPreferences")
    func initFromUserPreferences() {
        let prefs = UserPreferences.default
        let model = UserPreferencesModel(from: prefs)
        #expect(model.theme == prefs.theme.rawValue)
    }

    @Test("Convert to UserPreferences")
    func testToUserPreferences() {
        let prefs = UserPreferences.default
        let model = UserPreferencesModel(from: prefs)
        let converted = model.toUserPreferences()
        #expect(converted.theme == prefs.theme)
    }

    @Test("Default preferences")
    func defaultPreferences() {
        let model = UserPreferencesModel(from: .default)
        #expect(true) // Just verify it initializes
    }
}

@Suite("Mock Storage Service Error Handling Tests")
struct MockStorageServiceErrorTests {
    @Test("Fetch bookmarks error simulation")
    async func testFetchBookmarksError() async throws {
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
    async func testFetchPreferencesError() async throws {
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
