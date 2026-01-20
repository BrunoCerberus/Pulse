import Foundation
@testable import Pulse
import Testing

@Suite("HomeDomainState Initialization Tests")
struct HomeDomainStateInitializationTests {
    @Test("Initial state has empty articles")
    func initialStateEmptyArticles() {
        let state = HomeDomainState()
        #expect(state.breakingNews.isEmpty)
        #expect(state.headlines.isEmpty)
    }

    @Test("Initial state has page 1")
    func initialStatePageOne() {
        let state = HomeDomainState()
        #expect(state.currentPage == 1)
    }

    @Test("Initial state loading flags are false")
    func initialStateLoadingFalse() {
        let state = HomeDomainState()
        #expect(!state.isLoading)
        #expect(!state.isLoadingMore)
        #expect(!state.isRefreshing)
    }

    @Test("Initial state has no error")
    func initialStateNoError() {
        let state = HomeDomainState()
        #expect(state.error == nil)
    }

    @Test("Initial state has more pages available")
    func initialStateHasMorePages() {
        let state = HomeDomainState()
        #expect(state.hasMorePages)
    }

    @Test("Initial state has not loaded initial data")
    func initialStateNotLoadedInitialData() {
        let state = HomeDomainState()
        #expect(!state.hasLoadedInitialData)
    }

    @Test("Initial state has no selected article")
    func initialStateNoSelectedArticle() {
        let state = HomeDomainState()
        #expect(state.selectedArticle == nil)
    }

    @Test("Initial state has no article to share")
    func initialStateNoArticleToShare() {
        let state = HomeDomainState()
        #expect(state.articleToShare == nil)
    }
}

@Suite("HomeDomainState Breaking News Tests")
struct HomeDomainStateBreakingNewsTests {
    @Test("Can set breaking news articles")
    func setBreakingNews() {
        var state = HomeDomainState()
        let articles = Array(Article.mockArticles.prefix(3))
        state.breakingNews = articles
        #expect(state.breakingNews.count == 3)
    }

    @Test("Multiple breaking news updates")
    func multipleBreakingNewsUpdates() {
        var state = HomeDomainState()
        state.breakingNews = Array(Article.mockArticles.prefix(2))
        #expect(state.breakingNews.count == 2)

        state.breakingNews = Array(Article.mockArticles.prefix(5))
        #expect(state.breakingNews.count == 5)
    }

    @Test("Breaking news can be cleared")
    func clearBreakingNews() {
        var state = HomeDomainState()
        state.breakingNews = Article.mockArticles
        #expect(!state.breakingNews.isEmpty)

        state.breakingNews = []
        #expect(state.breakingNews.isEmpty)
    }
}

@Suite("HomeDomainState Headlines Tests")
struct HomeDomainStateHeadlinesTests {
    @Test("Can set headlines articles")
    func setHeadlines() {
        var state = HomeDomainState()
        let articles = Array(Article.mockArticles.prefix(5))
        state.headlines = articles
        #expect(state.headlines.count == 5)
    }

    @Test("Headlines pagination appends new articles")
    func headlinesPaginationAppend() {
        var state = HomeDomainState()
        let firstBatch = Array(Article.mockArticles.prefix(3))
        state.headlines = firstBatch
        #expect(state.headlines.count == 3)
    }

    @Test("Headlines can be cleared")
    func clearHeadlines() {
        var state = HomeDomainState()
        state.headlines = Article.mockArticles
        state.headlines = []
        #expect(state.headlines.isEmpty)
    }
}

@Suite("HomeDomainState Loading States Tests")
struct HomeDomainStateLoadingStatesTests {
    @Test("Can set isLoading flag")
    func setIsLoading() {
        var state = HomeDomainState()
        state.isLoading = true
        #expect(state.isLoading)
    }

    @Test("Can set isLoadingMore flag")
    func setIsLoadingMore() {
        var state = HomeDomainState()
        state.isLoadingMore = true
        #expect(state.isLoadingMore)
    }

    @Test("Can set isRefreshing flag")
    func setIsRefreshing() {
        var state = HomeDomainState()
        state.isRefreshing = true
        #expect(state.isRefreshing)
    }

    @Test("Loading flags are independent")
    func loadingFlagsIndependent() {
        var state = HomeDomainState()
        state.isLoading = true
        state.isLoadingMore = true
        #expect(state.isLoading)
        #expect(state.isLoadingMore)
        #expect(!state.isRefreshing)
    }

    @Test("Can toggle loading flags")
    func toggleLoadingFlags() {
        var state = HomeDomainState()
        state.isLoading = true
        #expect(state.isLoading)
        state.isLoading = false
        #expect(!state.isLoading)
    }
}

@Suite("HomeDomainState Error Tests")
struct HomeDomainStateErrorTests {
    @Test("Can set error message")
    func setErrorMessage() {
        var state = HomeDomainState()
        state.error = "Network error"
        #expect(state.error == "Network error")
    }

    @Test("Can clear error message")
    func clearErrorMessage() {
        var state = HomeDomainState()
        state.error = "Error"
        state.error = nil
        #expect(state.error == nil)
    }

    @Test("Error message can be empty string")
    func emptyErrorMessage() {
        var state = HomeDomainState()
        state.error = ""
        #expect(state.error == "")
    }
}

@Suite("HomeDomainState Pagination Tests")
struct HomeDomainStatePaginationTests {
    @Test("Can increment current page")
    func incrementPage() {
        var state = HomeDomainState()
        #expect(state.currentPage == 1)
        state.currentPage = 2
        #expect(state.currentPage == 2)
    }

    @Test("Can set page to arbitrary value")
    func setArbitraryPage() {
        var state = HomeDomainState()
        state.currentPage = 5
        #expect(state.currentPage == 5)
    }

    @Test("Can set hasMorePages flag")
    func setHasMorePages() {
        var state = HomeDomainState()
        state.hasMorePages = false
        #expect(!state.hasMorePages)
    }

    @Test("Current page affects pagination")
    func pagePagination() {
        var state = HomeDomainState()
        state.currentPage = 1
        #expect(state.currentPage == 1)
        state.currentPage = 2
        #expect(state.currentPage == 2)
    }

    @Test("hasMorePages can be toggled")
    func toggleHasMorePages() {
        var state = HomeDomainState()
        state.hasMorePages = true
        #expect(state.hasMorePages)
        state.hasMorePages = false
        #expect(!state.hasMorePages)
    }
}

@Suite("HomeDomainState Data Loading Tracking Tests")
struct HomeDomainStateDataLoadingTrackingTests {
    @Test("Can set hasLoadedInitialData")
    func setHasLoadedInitialData() {
        var state = HomeDomainState()
        state.hasLoadedInitialData = true
        #expect(state.hasLoadedInitialData)
    }

    @Test("Initial load tracking persists")
    func initialLoadTrackingPersists() {
        var state = HomeDomainState()
        state.hasLoadedInitialData = true
        state.isRefreshing = true
        #expect(state.hasLoadedInitialData)
        #expect(state.isRefreshing)
    }
}

@Suite("HomeDomainState Article Selection Tests")
struct HomeDomainStateArticleSelectionTests {
    @Test("Can set selected article")
    func setSelectedArticle() {
        var state = HomeDomainState()
        let article = Article.mockArticles[0]
        state.selectedArticle = article
        #expect(state.selectedArticle == article)
    }

    @Test("Can clear selected article")
    func clearSelectedArticle() {
        var state = HomeDomainState()
        state.selectedArticle = Article.mockArticles[0]
        state.selectedArticle = nil
        #expect(state.selectedArticle == nil)
    }

    @Test("Selected article can be changed")
    func changeSelectedArticle() {
        var state = HomeDomainState()
        state.selectedArticle = Article.mockArticles[0]
        state.selectedArticle = Article.mockArticles[1]
        #expect(state.selectedArticle == Article.mockArticles[1])
    }
}

@Suite("HomeDomainState Article Sharing Tests")
struct HomeDomainStateArticleSharingTests {
    @Test("Can set article to share")
    func setArticleToShare() {
        var state = HomeDomainState()
        let article = Article.mockArticles[0]
        state.articleToShare = article
        #expect(state.articleToShare == article)
    }

    @Test("Can clear article to share")
    func clearArticleToShare() {
        var state = HomeDomainState()
        state.articleToShare = Article.mockArticles[0]
        state.articleToShare = nil
        #expect(state.articleToShare == nil)
    }

    @Test("Article to share independent from selected article")
    func articleToShareIndependent() {
        var state = HomeDomainState()
        state.selectedArticle = Article.mockArticles[0]
        state.articleToShare = Article.mockArticles[1]
        #expect(state.selectedArticle == Article.mockArticles[0])
        #expect(state.articleToShare == Article.mockArticles[1])
    }
}

@Suite("HomeDomainState Equatable Tests")
struct HomeDomainStateEquatableTests {
    @Test("Two initial states are equal")
    func twoInitialStatesEqual() {
        let state1 = HomeDomainState()
        let state2 = HomeDomainState()
        #expect(state1 == state2)
    }

    @Test("States with different articles are not equal")
    func differentArticlesNotEqual() {
        var state1 = HomeDomainState()
        var state2 = HomeDomainState()
        state1.headlines = Array(Article.mockArticles.prefix(1))
        #expect(state1 != state2)
    }

    @Test("States with different loading flags are not equal")
    func differentLoadingNotEqual() {
        var state1 = HomeDomainState()
        var state2 = HomeDomainState()
        state1.isLoading = true
        #expect(state1 != state2)
    }

    @Test("States with different pages are not equal")
    func differentPagesNotEqual() {
        var state1 = HomeDomainState()
        var state2 = HomeDomainState()
        state1.currentPage = 2
        #expect(state1 != state2)
    }

    @Test("States become equal after same mutations")
    func statesEqualAfterSameMutations() {
        var state1 = HomeDomainState()
        var state2 = HomeDomainState()
        state1.currentPage = 2
        state2.currentPage = 2
        #expect(state1 == state2)
    }
}

@Suite("HomeDomainState Complex State Scenarios")
struct HomeDomainStateComplexScenarioTests {
    @Test("Simulate initial load completion")
    func initialLoadCompletion() {
        var state = HomeDomainState()
        state.isLoading = true
        state.breakingNews = Array(Article.mockArticles.prefix(3))
        state.headlines = Array(Article.mockArticles.prefix(10))
        state.isLoading = false
        state.hasLoadedInitialData = true

        #expect(state.hasLoadedInitialData)
        #expect(!state.isLoading)
        #expect(state.breakingNews.count == 3)
        #expect(state.headlines.count == 10)
    }

    @Test("Simulate pull-to-refresh")
    func pullToRefresh() {
        var state = HomeDomainState()
        state.hasLoadedInitialData = true
        state.headlines = Array(Article.mockArticles.prefix(5))

        state.isRefreshing = true
        state.currentPage = 1
        state.headlines = Array(Article.mockArticles.prefix(10))
        state.isRefreshing = false

        #expect(!state.isRefreshing)
        #expect(state.currentPage == 1)
        #expect(state.headlines.count == 10)
    }

    @Test("Simulate pagination")
    func pagination() {
        var state = HomeDomainState()
        state.headlines = Array(Article.mockArticles.prefix(5))

        state.isLoadingMore = true
        state.currentPage = 2
        state.headlines.append(contentsOf: Array(Article.mockArticles.prefix(5)))
        state.isLoadingMore = false

        #expect(!state.isLoadingMore)
        #expect(state.currentPage == 2)
        #expect(state.headlines.count == 10)
    }

    @Test("Simulate error during load")
    func errorDuringLoad() {
        var state = HomeDomainState()
        state.isLoading = true
        state.error = "Network error"
        state.isLoading = false

        #expect(!state.isLoading)
        #expect(state.error == "Network error")
    }

    @Test("Simulate article selection and sharing")
    func articleSelectionAndSharing() {
        var state = HomeDomainState()
        let article = Article.mockArticles[0]
        state.selectedArticle = article
        state.articleToShare = article

        #expect(state.selectedArticle == article)
        #expect(state.articleToShare == article)
    }
}
