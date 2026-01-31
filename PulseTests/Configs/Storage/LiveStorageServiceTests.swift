import Foundation
@testable import Pulse
import SwiftData
import Testing

@Suite("LiveStorageService Tests")
@MainActor
struct LiveStorageServiceTests {
    private var sut: LiveStorageService!

    private static let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)

    private var testArticle: Article {
        Article(
            id: "test-article-1",
            title: "Test Article",
            description: "Test description",
            content: "Test content",
            author: "Test Author",
            source: ArticleSource(id: "test-source", name: "Test Source"),
            url: "https://example.com/article",
            imageURL: "https://example.com/image.jpg",
            publishedAt: Self.referenceDate,
            category: .technology
        )
    }

    private var anotherArticle: Article {
        Article(
            id: "test-article-2",
            title: "Another Article",
            source: ArticleSource(id: "another-source", name: "Another Source"),
            url: "https://example.com/another",
            publishedAt: Self.referenceDate.addingTimeInterval(-3600),
            category: .business
        )
    }

    init() {
        sut = LiveStorageService(inMemory: true)
    }

    // MARK: - Bookmark Tests

    @Test("Save article adds bookmark")
    func saveArticleAddsBookmark() async throws {
        try await sut.saveArticle(testArticle)

        let bookmarks = try await sut.fetchBookmarkedArticles()
        #expect(bookmarks.count == 1)
        #expect(bookmarks.first?.id == testArticle.id)
    }

    @Test("Save duplicate article updates existing")
    func saveDuplicateUpdates() async throws {
        try await sut.saveArticle(testArticle)
        try await sut.saveArticle(testArticle)

        let bookmarks = try await sut.fetchBookmarkedArticles()
        #expect(bookmarks.count == 1)
    }

    @Test("Delete article removes bookmark")
    func deleteArticleRemovesBookmark() async throws {
        try await sut.saveArticle(testArticle)
        try await sut.deleteArticle(testArticle)

        let bookmarks = try await sut.fetchBookmarkedArticles()
        #expect(bookmarks.isEmpty)
    }

    @Test("Delete non-existent article does not throw")
    func deleteNonExistentDoesNotThrow() async throws {
        try await sut.deleteArticle(testArticle)
        // Should not throw
    }

    @Test("Fetch bookmarks returns articles in reverse chronological order")
    func fetchBookmarksOrder() async throws {
        try await sut.saveArticle(testArticle)
        try await Task.sleep(nanoseconds: 100_000_000) // Small delay
        try await sut.saveArticle(anotherArticle)

        let bookmarks = try await sut.fetchBookmarkedArticles()
        #expect(bookmarks.count == 2)
        #expect(bookmarks[0].id == anotherArticle.id) // Most recent first
        #expect(bookmarks[1].id == testArticle.id)
    }

    @Test("Is bookmarked returns true for saved article")
    func isBookmarkedTrue() async throws {
        try await sut.saveArticle(testArticle)

        let isBookmarked = await sut.isBookmarked(testArticle.id)
        #expect(isBookmarked == true)
    }

    @Test("Is bookmarked returns false for unsaved article")
    func isBookmarkedFalse() async {
        let isBookmarked = await sut.isBookmarked("non-existent-id")
        #expect(isBookmarked == false)
    }

    // MARK: - User Preferences Tests

    @Test("Save and fetch user preferences")
    func saveAndFetchPreferences() async throws {
        var preferences = UserPreferences.default
        preferences.notificationsEnabled = true
        preferences.followedTopics = [.technology, .business]

        try await sut.saveUserPreferences(preferences)

        let fetched = try await sut.fetchUserPreferences()
        #expect(fetched != nil)
        #expect(fetched?.notificationsEnabled == true)
        #expect(fetched?.followedTopics.count == 2)
    }

    @Test("Fetch user preferences returns nil when none saved")
    func fetchPreferencesNoneSaved() async throws {
        let fetched = try await sut.fetchUserPreferences()
        #expect(fetched == nil)
    }

    @Test("Save preferences overwrites existing")
    func savePreferencesOverwrites() async throws {
        var prefs1 = UserPreferences.default
        prefs1.notificationsEnabled = true
        try await sut.saveUserPreferences(prefs1)

        var prefs2 = UserPreferences.default
        prefs2.notificationsEnabled = false
        prefs2.breakingNewsNotifications = true
        try await sut.saveUserPreferences(prefs2)

        let fetched = try await sut.fetchUserPreferences()
        #expect(fetched?.notificationsEnabled == false)
        #expect(fetched?.breakingNewsNotifications == true)
    }

    // MARK: - Article Preservation Tests

    @Test("Saved article preserves all properties")
    func savedArticlePreservesProperties() async throws {
        try await sut.saveArticle(testArticle)

        let bookmarks = try await sut.fetchBookmarkedArticles()
        let saved = try #require(bookmarks.first)

        #expect(saved.id == testArticle.id)
        #expect(saved.title == testArticle.title)
        #expect(saved.description == testArticle.description)
        #expect(saved.author == testArticle.author)
        #expect(saved.source.id == testArticle.source.id)
        #expect(saved.url == testArticle.url)
        #expect(saved.imageURL == testArticle.imageURL)
        #expect(saved.category == testArticle.category)
    }
}
