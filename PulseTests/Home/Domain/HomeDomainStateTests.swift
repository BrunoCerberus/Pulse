import Foundation
@testable import Pulse
import Testing

@Suite("HomeDomainState Tests")
struct HomeDomainStateTests {
    // Use a fixed reference date to ensure consistent test results
    private static let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)

    private var testArticles: [Article] {
        [
            Article(
                id: "article-1",
                title: "Article 1",
                source: ArticleSource(id: "source-1", name: "Source 1"),
                url: "https://example.com/1",
                publishedAt: Self.referenceDate,
                category: .technology
            ),
            Article(
                id: "article-2",
                title: "Article 2",
                source: ArticleSource(id: "source-2", name: "Source 2"),
                url: "https://example.com/2",
                publishedAt: Self.referenceDate.addingTimeInterval(-3600),
                category: .business
            ),
        ]
    }

    // MARK: - Initial State Tests

    @Test("Initial state has correct default values")
    func initialState() {
        let state = HomeDomainState.initial

        #expect(state.breakingNews.isEmpty)
        #expect(state.headlines.isEmpty)
        #expect(state.isLoading == false)
        #expect(state.isLoadingMore == false)
        #expect(state.isRefreshing == false)
        #expect(state.error == nil)
        #expect(state.currentPage == 1)
        #expect(state.hasMorePages == true)
        #expect(state.hasLoadedInitialData == false)
        #expect(state.selectedArticle == nil)
        #expect(state.articleToShare == nil)
        #expect(state.selectedCategory == nil)
        #expect(state.followedTopics.isEmpty)
    }

    // MARK: - State Properties Tests

    @Test("Breaking news can be set")
    func breakingNewsCanBeSet() {
        var state = HomeDomainState.initial
        state.breakingNews = testArticles

        #expect(state.breakingNews.count == 2)
        #expect(state.breakingNews[0].id == "article-1")
    }

    @Test("Headlines can be set")
    func headlinesCanBeSet() {
        var state = HomeDomainState.initial
        state.headlines = testArticles

        #expect(state.headlines.count == 2)
        #expect(state.headlines[1].id == "article-2")
    }

    @Test("isLoading can be set")
    func isLoadingCanBeSet() {
        var state = HomeDomainState.initial
        #expect(state.isLoading == false)

        state.isLoading = true
        #expect(state.isLoading == true)
    }

    @Test("isLoadingMore can be set")
    func isLoadingMoreCanBeSet() {
        var state = HomeDomainState.initial
        #expect(state.isLoadingMore == false)

        state.isLoadingMore = true
        #expect(state.isLoadingMore == true)
    }

    @Test("isRefreshing can be set")
    func isRefreshingCanBeSet() {
        var state = HomeDomainState.initial
        #expect(state.isRefreshing == false)

        state.isRefreshing = true
        #expect(state.isRefreshing == true)
    }

    @Test("Error can be set")
    func errorCanBeSet() {
        var state = HomeDomainState.initial
        #expect(state.error == nil)

        state.error = "Network error"
        #expect(state.error == "Network error")
    }

    @Test("Current page can be changed")
    func currentPageCanBeChanged() {
        var state = HomeDomainState.initial
        #expect(state.currentPage == 1)

        state.currentPage = 2
        #expect(state.currentPage == 2)
    }

    @Test("hasMorePages can be changed")
    func hasMorePagesCanBeChanged() {
        var state = HomeDomainState.initial
        #expect(state.hasMorePages == true)

        state.hasMorePages = false
        #expect(state.hasMorePages == false)
    }

    @Test("hasLoadedInitialData can be set")
    func hasLoadedInitialDataCanBeSet() {
        var state = HomeDomainState.initial
        #expect(state.hasLoadedInitialData == false)

        state.hasLoadedInitialData = true
        #expect(state.hasLoadedInitialData == true)
    }

    @Test("Selected article can be set")
    func selectedArticleCanBeSet() {
        var state = HomeDomainState.initial
        state.selectedArticle = testArticles[0]

        #expect(state.selectedArticle?.id == "article-1")
    }

    @Test("Article to share can be set")
    func articleToShareCanBeSet() {
        var state = HomeDomainState.initial
        state.articleToShare = testArticles[1]

        #expect(state.articleToShare?.id == "article-2")
    }

    @Test("Selected category can be set")
    func selectedCategoryCanBeSet() {
        var state = HomeDomainState.initial
        state.selectedCategory = .technology

        #expect(state.selectedCategory == .technology)
    }

    @Test("Selected category can be nil")
    func selectedCategoryCanBeNil() {
        var state = HomeDomainState.initial
        state.selectedCategory = .business
        #expect(state.selectedCategory != nil)

        state.selectedCategory = nil
        #expect(state.selectedCategory == nil)
    }

    @Test("Followed topics can be set")
    func followedTopicsCanBeSet() {
        var state = HomeDomainState.initial
        state.followedTopics = [.technology, .business, .science]

        #expect(state.followedTopics.count == 3)
        #expect(state.followedTopics.contains(.technology))
        #expect(state.followedTopics.contains(.business))
        #expect(state.followedTopics.contains(.science))
    }

    // MARK: - Equatable Tests

    @Test("Same initial states are equal")
    func sameInitialStatesAreEqual() {
        let state1 = HomeDomainState.initial
        let state2 = HomeDomainState.initial

        #expect(state1 == state2)
    }

    @Test("States with different breakingNews are not equal")
    func statesWithDifferentBreakingNews() {
        let state1 = HomeDomainState.initial
        var state2 = HomeDomainState.initial
        state2.breakingNews = testArticles

        #expect(state1 != state2)
    }

    @Test("States with different headlines are not equal")
    func statesWithDifferentHeadlines() {
        let state1 = HomeDomainState.initial
        var state2 = HomeDomainState.initial
        state2.headlines = testArticles

        #expect(state1 != state2)
    }

    @Test("States with different isLoading are not equal")
    func statesWithDifferentIsLoading() {
        let state1 = HomeDomainState.initial
        var state2 = HomeDomainState.initial
        state2.isLoading = true

        #expect(state1 != state2)
    }

    @Test("States with different isLoadingMore are not equal")
    func statesWithDifferentIsLoadingMore() {
        let state1 = HomeDomainState.initial
        var state2 = HomeDomainState.initial
        state2.isLoadingMore = true

        #expect(state1 != state2)
    }

    @Test("States with different isRefreshing are not equal")
    func statesWithDifferentIsRefreshing() {
        let state1 = HomeDomainState.initial
        var state2 = HomeDomainState.initial
        state2.isRefreshing = true

        #expect(state1 != state2)
    }

    @Test("States with different errors are not equal")
    func statesWithDifferentErrors() {
        let state1 = HomeDomainState.initial
        var state2 = HomeDomainState.initial
        state2.error = "Error message"

        #expect(state1 != state2)
    }

    @Test("States with different currentPage are not equal")
    func statesWithDifferentCurrentPage() {
        let state1 = HomeDomainState.initial
        var state2 = HomeDomainState.initial
        state2.currentPage = 3

        #expect(state1 != state2)
    }

    @Test("States with different hasMorePages are not equal")
    func statesWithDifferentHasMorePages() {
        let state1 = HomeDomainState.initial
        var state2 = HomeDomainState.initial
        state2.hasMorePages = false

        #expect(state1 != state2)
    }

    @Test("States with different hasLoadedInitialData are not equal")
    func statesWithDifferentHasLoadedInitialData() {
        let state1 = HomeDomainState.initial
        var state2 = HomeDomainState.initial
        state2.hasLoadedInitialData = true

        #expect(state1 != state2)
    }

    @Test("States with different selectedArticle are not equal")
    func statesWithDifferentSelectedArticle() {
        let state1 = HomeDomainState.initial
        var state2 = HomeDomainState.initial
        state2.selectedArticle = testArticles[0]

        #expect(state1 != state2)
    }

    @Test("States with different articleToShare are not equal")
    func statesWithDifferentArticleToShare() {
        let state1 = HomeDomainState.initial
        var state2 = HomeDomainState.initial
        state2.articleToShare = testArticles[0]

        #expect(state1 != state2)
    }

    @Test("States with different selectedCategory are not equal")
    func statesWithDifferentSelectedCategory() {
        let state1 = HomeDomainState.initial
        var state2 = HomeDomainState.initial
        state2.selectedCategory = .technology

        #expect(state1 != state2)
    }

    @Test("States with different followedTopics are not equal")
    func statesWithDifferentFollowedTopics() {
        let state1 = HomeDomainState.initial
        var state2 = HomeDomainState.initial
        state2.followedTopics = [.technology, .health]

        #expect(state1 != state2)
    }

    @Test("States with same values are equal")
    func statesWithSameValuesAreEqual() {
        var state1 = HomeDomainState.initial
        state1.breakingNews = testArticles
        state1.headlines = testArticles
        state1.isLoading = true
        state1.currentPage = 2
        state1.followedTopics = [.technology]

        var state2 = HomeDomainState.initial
        state2.breakingNews = testArticles
        state2.headlines = testArticles
        state2.isLoading = true
        state2.currentPage = 2
        state2.followedTopics = [.technology]

        #expect(state1 == state2)
    }
}
