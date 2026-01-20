import Foundation
@testable import Pulse
import Testing

@Suite("ForYouDomainState Initialization Tests")
struct ForYouDomainStateInitializationTests {
    @Test("Initial state has empty articles")
    func initialStateEmptyArticles() {
        let state = ForYouDomainState()
        #expect(state.articles.isEmpty)
    }

    @Test("Initial state has default preferences")
    func initialStateDefaultPreferences() {
        let state = ForYouDomainState()
        #expect(state.preferences == UserPreferences.default)
    }

    @Test("Initial state has page 1")
    func initialStatePageOne() {
        let state = ForYouDomainState()
        #expect(state.currentPage == 1)
    }

    @Test("Initial state loading flags are false")
    func initialStateLoadingFalse() {
        let state = ForYouDomainState()
        #expect(!state.isLoading)
        #expect(!state.isLoadingMore)
        #expect(!state.isRefreshing)
    }

    @Test("Initial state has no error")
    func initialStateNoError() {
        let state = ForYouDomainState()
        #expect(state.error == nil)
    }

    @Test("Initial state has more pages")
    func initialStateHasMorePages() {
        let state = ForYouDomainState()
        #expect(state.hasMorePages)
    }

    @Test("Initial state has not loaded initial data")
    func initialStateNotLoadedInitialData() {
        let state = ForYouDomainState()
        #expect(!state.hasLoadedInitialData)
    }

    @Test("Initial state has no selected article")
    func initialStateNoSelectedArticle() {
        let state = ForYouDomainState()
        #expect(state.selectedArticle == nil)
    }
}

@Suite("ForYouDomainState Articles Tests")
struct ForYouDomainStateArticlesTests {
    @Test("Can set articles")
    func setArticles() {
        var state = ForYouDomainState()
        let articles = Array(Article.mockArticles.prefix(5))
        state.articles = articles
        #expect(state.articles.count == 5)
    }

    @Test("Can append articles for pagination")
    func appendArticles() {
        var state = ForYouDomainState()
        state.articles = Array(Article.mockArticles.prefix(3))
        state.articles.append(contentsOf: Array(Article.mockArticles.suffix(2)))
        #expect(state.articles.count == 5)
    }

    @Test("Can clear articles")
    func clearArticles() {
        var state = ForYouDomainState()
        state.articles = Article.mockArticles
        state.articles = []
        #expect(state.articles.isEmpty)
    }
}

@Suite("ForYouDomainState Preferences Tests")
struct ForYouDomainStatePreferencesTests {
    @Test("Can set custom preferences")
    func setCustomPreferences() {
        var state = ForYouDomainState()
        var prefs = UserPreferences.default
        prefs.notificationsEnabled = false
        state.preferences = prefs
        #expect(state.preferences.notificationsEnabled == false)
    }

    @Test("Preferences changes don't affect default")
    func preferencesIndependentFromDefault() {
        var state = ForYouDomainState()
        var prefs = state.preferences
        prefs.breakingNewsNotifications = false
        state.preferences = prefs
        #expect(state.preferences.breakingNewsNotifications == false)
        #expect(UserPreferences.default.breakingNewsNotifications == true)
    }

    @Test("Can reset preferences to default")
    func resetPreferencesToDefault() {
        var state = ForYouDomainState()
        var prefs = UserPreferences.default
        prefs.notificationsEnabled = false
        state.preferences = prefs
        state.preferences = UserPreferences.default
        #expect(state.preferences == UserPreferences.default)
    }
}

@Suite("ForYouDomainState Loading States Tests")
struct ForYouDomainStateLoadingStatesTests {
    @Test("Can set isLoading flag")
    func setIsLoading() {
        var state = ForYouDomainState()
        state.isLoading = true
        #expect(state.isLoading)
    }

    @Test("Can set isLoadingMore flag")
    func setIsLoadingMore() {
        var state = ForYouDomainState()
        state.isLoadingMore = true
        #expect(state.isLoadingMore)
    }

    @Test("Can set isRefreshing flag")
    func setIsRefreshing() {
        var state = ForYouDomainState()
        state.isRefreshing = true
        #expect(state.isRefreshing)
    }

    @Test("Loading flags are independent")
    func loadingFlagsIndependent() {
        var state = ForYouDomainState()
        state.isLoading = true
        state.isLoadingMore = true
        #expect(state.isLoading)
        #expect(state.isLoadingMore)
        #expect(!state.isRefreshing)
    }
}

@Suite("ForYouDomainState Error Tests")
struct ForYouDomainStateErrorTests {
    @Test("Can set error message")
    func setErrorMessage() {
        var state = ForYouDomainState()
        state.error = "Failed to load personalized feed"
        #expect(state.error == "Failed to load personalized feed")
    }

    @Test("Can clear error")
    func clearError() {
        var state = ForYouDomainState()
        state.error = "Error"
        state.error = nil
        #expect(state.error == nil)
    }
}

@Suite("ForYouDomainState Pagination Tests")
struct ForYouDomainStatePaginationTests {
    @Test("Can increment page")
    func incrementPage() {
        var state = ForYouDomainState()
        state.currentPage = 2
        #expect(state.currentPage == 2)
    }

    @Test("Can set hasMorePages")
    func setHasMorePages() {
        var state = ForYouDomainState()
        state.hasMorePages = false
        #expect(!state.hasMorePages)
    }

    @Test("Current page and hasMorePages are independent")
    func pageAndHasMorePagesIndependent() {
        var state = ForYouDomainState()
        state.currentPage = 5
        state.hasMorePages = false
        #expect(state.currentPage == 5)
        #expect(!state.hasMorePages)
    }
}

@Suite("ForYouDomainState Data Loading Tracking Tests")
struct ForYouDomainStateDataLoadingTrackingTests {
    @Test("Can set hasLoadedInitialData")
    func setHasLoadedInitialData() {
        var state = ForYouDomainState()
        state.hasLoadedInitialData = true
        #expect(state.hasLoadedInitialData)
    }

    @Test("Initial data flag persists through updates")
    func initialDataFlagPersists() {
        var state = ForYouDomainState()
        state.hasLoadedInitialData = true
        state.articles = Array(Article.mockArticles.prefix(5))
        #expect(state.hasLoadedInitialData)
    }
}

@Suite("ForYouDomainState Article Selection Tests")
struct ForYouDomainStateArticleSelectionTests {
    @Test("Can set selected article")
    func setSelectedArticle() {
        var state = ForYouDomainState()
        let article = Article.mockArticles[0]
        state.selectedArticle = article
        #expect(state.selectedArticle == article)
    }

    @Test("Can clear selected article")
    func clearSelectedArticle() {
        var state = ForYouDomainState()
        state.selectedArticle = Article.mockArticles[0]
        state.selectedArticle = nil
        #expect(state.selectedArticle == nil)
    }

    @Test("Can change selected article")
    func changeSelectedArticle() {
        var state = ForYouDomainState()
        state.selectedArticle = Article.mockArticles[0]
        state.selectedArticle = Article.mockArticles[1]
        #expect(state.selectedArticle == Article.mockArticles[1])
    }
}

@Suite("ForYouDomainState Equatable Tests")
struct ForYouDomainStateEquatableTests {
    @Test("Two initial states are equal")
    func twoInitialStatesEqual() {
        let state1 = ForYouDomainState()
        let state2 = ForYouDomainState()
        #expect(state1 == state2)
    }

    @Test("States with different articles are not equal")
    func differentArticlesNotEqual() {
        var state1 = ForYouDomainState()
        var state2 = ForYouDomainState()
        state1.articles = Array(Article.mockArticles.prefix(1))
        #expect(state1 != state2)
    }

    @Test("States with different preferences are not equal")
    func differentPreferencesNotEqual() {
        var state1 = ForYouDomainState()
        var state2 = ForYouDomainState()
        var prefs = UserPreferences.default
        prefs.breakingNewsNotifications = false
        state1.preferences = prefs
        #expect(state1 != state2)
    }

    @Test("States with different loading flags are not equal")
    func differentLoadingNotEqual() {
        var state1 = ForYouDomainState()
        var state2 = ForYouDomainState()
        state1.isLoading = true
        #expect(state1 != state2)
    }

    @Test("States become equal after same mutations")
    func statesEqualAfterSameMutations() {
        var state1 = ForYouDomainState()
        var state2 = ForYouDomainState()
        state1.currentPage = 2
        state2.currentPage = 2
        #expect(state1 == state2)
    }
}

@Suite("ForYouDomainState Complex State Scenarios")
struct ForYouDomainStateComplexScenarioTests {
    @Test("Simulate initial load with personalized content")
    func initialLoadWithPersonalizedContent() {
        var state = ForYouDomainState()
        state.isLoading = true
        state.articles = Array(Article.mockArticles.prefix(10))
        state.isLoading = false
        state.hasLoadedInitialData = true

        #expect(!state.isLoading)
        #expect(state.hasLoadedInitialData)
        #expect(state.articles.count == 10)
    }

    @Test("Simulate preference changes affecting feed")
    func preferenceChangesAffectingFeed() {
        var state = ForYouDomainState()
        state.hasLoadedInitialData = true
        state.articles = Array(Article.mockArticles.prefix(5))

        var newPrefs = state.preferences
        newPrefs.theme = .dark
        state.preferences = newPrefs
        state.isRefreshing = true
        state.articles = Array(Article.mockArticles.prefix(8))
        state.isRefreshing = false

        #expect(state.preferences.breakingNewsNotifications == false)
        #expect(!state.isRefreshing)
        #expect(state.articles.count == 8)
    }

    @Test("Simulate pagination for personalized feed")
    func paginationForPersonalizedFeed() {
        var state = ForYouDomainState()
        state.articles = Array(Article.mockArticles.prefix(5))

        state.isLoadingMore = true
        state.currentPage = 2
        state.articles.append(contentsOf: Array(Article.mockArticles.prefix(5)))
        state.isLoadingMore = false

        #expect(!state.isLoadingMore)
        #expect(state.currentPage == 2)
        #expect(state.articles.count == 10)
    }

    @Test("Simulate error during personalized feed load")
    func errorDuringPersonalizedFeedLoad() {
        var state = ForYouDomainState()
        state.isLoading = true
        state.error = "Failed to fetch personalized feed"
        state.isLoading = false

        #expect(!state.isLoading)
        #expect(state.error == "Failed to fetch personalized feed")
    }
}
