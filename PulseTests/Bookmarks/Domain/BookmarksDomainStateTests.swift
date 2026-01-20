import Foundation
@testable import Pulse
import Testing

@Suite("BookmarksDomainState Initialization Tests")
struct BookmarksDomainStateInitializationTests {
    @Test("Initial bookmarks are empty")
    func initialBookmarksEmpty() {
        let state = BookmarksDomainState()
        #expect(state.bookmarks.isEmpty)
    }

    @Test("Initial isLoading is false")
    func initialIsLoadingFalse() {
        let state = BookmarksDomainState()
        #expect(!state.isLoading)
    }

    @Test("Initial isRefreshing is false")
    func initialIsRefreshingFalse() {
        let state = BookmarksDomainState()
        #expect(!state.isRefreshing)
    }

    @Test("Initial error is nil")
    func initialErrorNil() {
        let state = BookmarksDomainState()
        #expect(state.error == nil)
    }

    @Test("Initial selectedArticle is nil")
    func initialSelectedArticleNil() {
        let state = BookmarksDomainState()
        #expect(state.selectedArticle == nil)
    }
}

@Suite("BookmarksDomainState Bookmarks Management Tests")
struct BookmarksDomainStateBookmarksManagementTests {
    @Test("Can set bookmarks array")
    func setBookmarks() {
        var state = BookmarksDomainState()
        let articles = Array(Article.mockArticles.prefix(3))
        state.bookmarks = articles
        #expect(state.bookmarks.count == 3)
    }

    @Test("Can append bookmark")
    func appendBookmark() {
        var state = BookmarksDomainState()
        state.bookmarks = [Article.mockArticles[0]]
        state.bookmarks.append(Article.mockArticles[1])
        #expect(state.bookmarks.count == 2)
    }

    @Test("Can remove bookmark by index")
    func removeBookmarkByIndex() {
        var state = BookmarksDomainState()
        state.bookmarks = Array(Article.mockArticles.prefix(3))
        state.bookmarks.remove(at: 0)
        #expect(state.bookmarks.count == 2)
    }

    @Test("Can remove all bookmarks")
    func removeAllBookmarks() {
        var state = BookmarksDomainState()
        state.bookmarks = Article.mockArticles
        state.bookmarks = []
        #expect(state.bookmarks.isEmpty)
    }

    @Test("Can check if specific article is bookmarked")
    func checkIfArticleBookmarked() {
        var state = BookmarksDomainState()
        let article = Article.mockArticles[0]
        state.bookmarks = [article]
        #expect(state.bookmarks.contains { $0.id == article.id })
    }

    @Test("Multiple bookmarks can be stored")
    func multipleBookmarks() {
        var state = BookmarksDomainState()
        let articles = Article.mockArticles
        state.bookmarks = articles
        #expect(state.bookmarks.count == articles.count)
    }
}

@Suite("BookmarksDomainState Loading States Tests")
struct BookmarksDomainStateLoadingStatesTests {
    @Test("Can set isLoading flag")
    func setIsLoading() {
        var state = BookmarksDomainState()
        state.isLoading = true
        #expect(state.isLoading)
    }

    @Test("Can clear isLoading flag")
    func clearIsLoading() {
        var state = BookmarksDomainState()
        state.isLoading = true
        state.isLoading = false
        #expect(!state.isLoading)
    }

    @Test("Can set isRefreshing flag")
    func setIsRefreshing() {
        var state = BookmarksDomainState()
        state.isRefreshing = true
        #expect(state.isRefreshing)
    }

    @Test("Can clear isRefreshing flag")
    func clearIsRefreshing() {
        var state = BookmarksDomainState()
        state.isRefreshing = true
        state.isRefreshing = false
        #expect(!state.isRefreshing)
    }

    @Test("Loading and refreshing flags are independent")
    func loadingAndRefreshingIndependent() {
        var state = BookmarksDomainState()
        state.isLoading = true
        state.isRefreshing = true
        #expect(state.isLoading)
        #expect(state.isRefreshing)

        state.isLoading = false
        #expect(!state.isLoading)
        #expect(state.isRefreshing)
    }
}

@Suite("BookmarksDomainState Error Tests")
struct BookmarksDomainStateErrorTests {
    @Test("Can set error message")
    func setErrorMessage() {
        var state = BookmarksDomainState()
        state.error = "Failed to load bookmarks"
        #expect(state.error == "Failed to load bookmarks")
    }

    @Test("Can clear error message")
    func clearErrorMessage() {
        var state = BookmarksDomainState()
        state.error = "Error"
        state.error = nil
        #expect(state.error == nil)
    }

    @Test("Can change error message")
    func changeErrorMessage() {
        var state = BookmarksDomainState()
        state.error = "Error 1"
        state.error = "Error 2"
        #expect(state.error == "Error 2")
    }

    @Test("Error can be empty string")
    func emptyErrorString() {
        var state = BookmarksDomainState()
        state.error = ""
        #expect(state.error == "")
    }
}

@Suite("BookmarksDomainState Article Selection Tests")
struct BookmarksDomainStateArticleSelectionTests {
    @Test("Can set selected article")
    func setSelectedArticle() {
        var state = BookmarksDomainState()
        let article = Article.mockArticles[0]
        state.selectedArticle = article
        #expect(state.selectedArticle == article)
    }

    @Test("Can clear selected article")
    func clearSelectedArticle() {
        var state = BookmarksDomainState()
        state.selectedArticle = Article.mockArticles[0]
        state.selectedArticle = nil
        #expect(state.selectedArticle == nil)
    }

    @Test("Can change selected article")
    func changeSelectedArticle() {
        var state = BookmarksDomainState()
        state.selectedArticle = Article.mockArticles[0]
        state.selectedArticle = Article.mockArticles[1]
        #expect(state.selectedArticle == Article.mockArticles[1])
    }

    @Test("Selected article can be from bookmarks")
    func selectedArticleFromBookmarks() {
        var state = BookmarksDomainState()
        state.bookmarks = Array(Article.mockArticles.prefix(3))
        state.selectedArticle = state.bookmarks[0]
        #expect(state.selectedArticle == state.bookmarks[0])
    }
}

@Suite("BookmarksDomainState Equatable Tests")
struct BookmarksDomainStateEquatableTests {
    @Test("Two initial states are equal")
    func twoInitialStatesEqual() {
        let state1 = BookmarksDomainState()
        let state2 = BookmarksDomainState()
        #expect(state1 == state2)
    }

    @Test("States with different bookmarks are not equal")
    func differentBookmarksNotEqual() {
        var state1 = BookmarksDomainState()
        var state2 = BookmarksDomainState()
        state1.bookmarks = Array(Article.mockArticles.prefix(1))
        #expect(state1 != state2)
    }

    @Test("States with different loading flags are not equal")
    func differentIsLoadingNotEqual() {
        var state1 = BookmarksDomainState()
        var state2 = BookmarksDomainState()
        state1.isLoading = true
        #expect(state1 != state2)
    }

    @Test("States with different refresh flags are not equal")
    func differentIsRefreshingNotEqual() {
        var state1 = BookmarksDomainState()
        var state2 = BookmarksDomainState()
        state1.isRefreshing = true
        #expect(state1 != state2)
    }

    @Test("States with different errors are not equal")
    func differentErrorNotEqual() {
        var state1 = BookmarksDomainState()
        var state2 = BookmarksDomainState()
        state1.error = "Error"
        #expect(state1 != state2)
    }

    @Test("States with different selected articles are not equal")
    func differentSelectedArticleNotEqual() {
        var state1 = BookmarksDomainState()
        var state2 = BookmarksDomainState()
        state1.selectedArticle = Article.mockArticles[0]
        #expect(state1 != state2)
    }

    @Test("States become equal after same mutations")
    func statesEqualAfterSameMutations() {
        var state1 = BookmarksDomainState()
        var state2 = BookmarksDomainState()
        let articles = Array(Article.mockArticles.prefix(2))
        state1.bookmarks = articles
        state2.bookmarks = articles
        #expect(state1 == state2)
    }
}

@Suite("BookmarksDomainState Complex Bookmark Scenarios")
struct BookmarksDomainStateComplexBookmarkScenarioTests {
    @Test("Simulate loading bookmarks")
    func loadingBookmarks() {
        var state = BookmarksDomainState()
        state.isLoading = true
        state.bookmarks = []

        state.bookmarks = Array(Article.mockArticles.prefix(10))
        state.isLoading = false

        #expect(!state.isLoading)
        #expect(state.bookmarks.count == 10)
    }

    @Test("Simulate adding and removing bookmarks")
    func addingAndRemovingBookmarks() {
        var state = BookmarksDomainState()
        let article1 = Article.mockArticles[0]
        let article2 = Article.mockArticles[1]

        state.bookmarks.append(article1)
        #expect(state.bookmarks.count == 1)

        state.bookmarks.append(article2)
        #expect(state.bookmarks.count == 2)

        state.bookmarks.remove(at: 0)
        #expect(state.bookmarks.count == 1)
        #expect(state.bookmarks[0] == article2)
    }

    @Test("Simulate refresh of bookmarks")
    func refreshBookmarks() {
        var state = BookmarksDomainState()
        state.bookmarks = Array(Article.mockArticles.prefix(5))

        state.isRefreshing = true
        state.bookmarks = Array(Article.mockArticles.prefix(8))
        state.isRefreshing = false

        #expect(!state.isRefreshing)
        #expect(state.bookmarks.count == 8)
    }

    @Test("Simulate error loading bookmarks")
    func errorLoadingBookmarks() {
        var state = BookmarksDomainState()
        state.isLoading = true
        state.error = "Failed to fetch bookmarks"
        state.isLoading = false

        #expect(!state.isLoading)
        #expect(state.error == "Failed to fetch bookmarks")
        #expect(state.bookmarks.isEmpty)
    }

    @Test("Simulate article selection from bookmarks")
    func articleSelectionFromBookmarks() {
        var state = BookmarksDomainState()
        state.bookmarks = Array(Article.mockArticles.prefix(5))
        state.selectedArticle = state.bookmarks[2]

        #expect(state.selectedArticle == state.bookmarks[2])
        #expect(state.bookmarks.count == 5)
    }

    @Test("Simulate clearing all bookmarks")
    func clearingAllBookmarks() {
        var state = BookmarksDomainState()
        state.bookmarks = Article.mockArticles
        state.selectedArticle = Article.mockArticles[0]

        state.bookmarks = []
        state.selectedArticle = nil

        #expect(state.bookmarks.isEmpty)
        #expect(state.selectedArticle == nil)
    }

    @Test("Simulate multiple operations on bookmarks")
    func multipleOperationsOnBookmarks() {
        var state = BookmarksDomainState()

        // Load initial bookmarks
        state.isLoading = true
        state.bookmarks = Array(Article.mockArticles.prefix(5))
        state.isLoading = false

        // Select one
        state.selectedArticle = state.bookmarks[0]

        // Refresh
        state.isRefreshing = true
        state.bookmarks = Array(Article.mockArticles.prefix(7))
        state.isRefreshing = false

        // Select different one
        state.selectedArticle = state.bookmarks[3]

        // Remove one
        state.bookmarks.remove(at: 0)

        #expect(state.bookmarks.count == 6)
        #expect(state.selectedArticle == state.bookmarks[2])
    }
}
