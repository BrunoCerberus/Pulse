import Foundation
@testable import Pulse
import Testing

@Suite("BookmarksDomainState Tests")
struct BookmarksDomainStateTests {
    // Use a fixed reference date to ensure consistent test results
    private static let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)

    private var testArticles: [Article] {
        [
            Article(
                id: "article-1",
                title: "Article 1",
                source: ArticleSource(id: "source-1", name: "Source 1"),
                url: "https://example.com/1",
                publishedAt: Self.referenceDate
            ),
            Article(
                id: "article-2",
                title: "Article 2",
                source: ArticleSource(id: "source-2", name: "Source 2"),
                url: "https://example.com/2",
                publishedAt: Self.referenceDate.addingTimeInterval(-3600)
            ),
        ]
    }

    // MARK: - Initial State Tests

    @Test("Initial state has correct default values")
    func initialState() {
        let state = BookmarksDomainState.initial

        #expect(state.bookmarks.isEmpty)
        #expect(state.isLoading == false)
        #expect(state.isRefreshing == false)
        #expect(state.error == nil)
        #expect(state.selectedArticle == nil)
    }

    // MARK: - State Properties Tests

    @Test("Bookmarks can be set")
    func bookmarksCanBeSet() {
        var state = BookmarksDomainState.initial
        state.bookmarks = testArticles

        #expect(state.bookmarks.count == 2)
        #expect(state.bookmarks[0].id == "article-1")
        #expect(state.bookmarks[1].id == "article-2")
    }

    @Test("isLoading can be set")
    func isLoadingCanBeSet() {
        var state = BookmarksDomainState.initial
        #expect(state.isLoading == false)

        state.isLoading = true
        #expect(state.isLoading == true)
    }

    @Test("isRefreshing can be set")
    func isRefreshingCanBeSet() {
        var state = BookmarksDomainState.initial
        #expect(state.isRefreshing == false)

        state.isRefreshing = true
        #expect(state.isRefreshing == true)
    }

    @Test("Error can be set")
    func errorCanBeSet() {
        var state = BookmarksDomainState.initial
        #expect(state.error == nil)

        state.error = "Network error"
        #expect(state.error == "Network error")
    }

    @Test("Selected article can be set")
    func selectedArticleCanBeSet() {
        var state = BookmarksDomainState.initial
        #expect(state.selectedArticle == nil)

        state.selectedArticle = testArticles[0]
        #expect(state.selectedArticle?.id == "article-1")
    }

    @Test("Selected article can be cleared")
    func selectedArticleCanBeCleared() {
        var state = BookmarksDomainState.initial
        state.selectedArticle = testArticles[0]
        #expect(state.selectedArticle != nil)

        state.selectedArticle = nil
        #expect(state.selectedArticle == nil)
    }

    // MARK: - Equatable Tests

    @Test("Same states are equal")
    func sameStatesAreEqual() {
        let state1 = BookmarksDomainState.initial
        let state2 = BookmarksDomainState.initial

        #expect(state1 == state2)
    }

    @Test("States with different bookmarks are not equal")
    func statesWithDifferentBookmarks() {
        let state1 = BookmarksDomainState.initial
        var state2 = BookmarksDomainState.initial
        state2.bookmarks = testArticles

        #expect(state1 != state2)
    }

    @Test("States with different isLoading are not equal")
    func statesWithDifferentIsLoading() {
        let state1 = BookmarksDomainState.initial
        var state2 = BookmarksDomainState.initial
        state2.isLoading = true

        #expect(state1 != state2)
    }

    @Test("States with different isRefreshing are not equal")
    func statesWithDifferentIsRefreshing() {
        let state1 = BookmarksDomainState.initial
        var state2 = BookmarksDomainState.initial
        state2.isRefreshing = true

        #expect(state1 != state2)
    }

    @Test("States with different errors are not equal")
    func statesWithDifferentErrors() {
        let state1 = BookmarksDomainState.initial
        var state2 = BookmarksDomainState.initial
        state2.error = "Error message"

        #expect(state1 != state2)
    }

    @Test("States with different selected articles are not equal")
    func statesWithDifferentSelectedArticles() {
        let state1 = BookmarksDomainState.initial
        var state2 = BookmarksDomainState.initial
        state2.selectedArticle = testArticles[0]

        #expect(state1 != state2)
    }

    @Test("States with same values are equal")
    func statesWithSameValuesAreEqual() {
        var state1 = BookmarksDomainState.initial
        state1.bookmarks = testArticles
        state1.isLoading = true
        state1.error = "Test error"

        var state2 = BookmarksDomainState.initial
        state2.bookmarks = testArticles
        state2.isLoading = true
        state2.error = "Test error"

        #expect(state1 == state2)
    }
}
