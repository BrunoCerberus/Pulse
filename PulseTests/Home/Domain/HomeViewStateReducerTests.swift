import Foundation
@testable import Pulse
import Testing

@Suite("HomeViewStateReducer Tests")
struct HomeViewStateReducerTests {
    let sut = HomeViewStateReducer()

    /// Helper to create domain state with defaults
    private func makeDomainState(
        breakingNews: [Article] = [],
        headlines: [Article] = [],
        isLoading: Bool = false,
        isLoadingMore: Bool = false,
        isRefreshing: Bool = false,
        error: String? = nil,
        currentPage: Int = 1,
        hasMorePages: Bool = true,
        hasLoadedInitialData: Bool = true,
        selectedArticle: Article? = nil,
        articleToShare: Article? = nil,
        selectedCategory: NewsCategory? = nil,
        followedTopics: [NewsCategory] = [],
        allTopics: [NewsCategory] = NewsCategory.allCases,
        isEditingTopics: Bool = false,
        isOfflineError: Bool = false,
        readArticleIDs: Set<String> = [],
        recentlyRead: [Article] = []
    ) -> HomeDomainState {
        HomeDomainState(
            breakingNews: breakingNews,
            headlines: headlines,
            isLoading: isLoading,
            isLoadingMore: isLoadingMore,
            isRefreshing: isRefreshing,
            error: error,
            currentPage: currentPage,
            hasMorePages: hasMorePages,
            hasLoadedInitialData: hasLoadedInitialData,
            selectedArticle: selectedArticle,
            articleToShare: articleToShare,
            selectedCategory: selectedCategory,
            followedTopics: followedTopics,
            allTopics: allTopics,
            isEditingTopics: isEditingTopics,
            isOfflineError: isOfflineError,
            readArticleIDs: readArticleIDs,
            recentlyRead: recentlyRead
        )
    }

    // MARK: - Basic Transformation Tests

    @Test("Reduce transforms breaking news and headlines to ArticleViewItems")
    func reduceTransformsArticlesToViewItems() {
        let domainState = makeDomainState(
            breakingNews: Article.mockArticles,
            headlines: Article.mockArticles
        )

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.breakingNews.count == Article.mockArticles.count)
        #expect(viewState.breakingNews[0].id == Article.mockArticles[0].id)
        #expect(viewState.breakingNews[0].title == Article.mockArticles[0].title)
        #expect(viewState.headlines.count == Article.mockArticles.count)
        #expect(viewState.headlines[0].id == Article.mockArticles[0].id)
    }

    // MARK: - Loading State Tests (Consolidated)

    @Test("Reduce passes through all loading states correctly")
    func reducePassesThroughAllLoadingStates() {
        let loadingState = makeDomainState(isLoading: true)
        let loadingMoreState = makeDomainState(headlines: Article.mockArticles, isLoadingMore: true)
        let refreshingState = makeDomainState(isRefreshing: true)

        let loadingViewState = sut.reduce(domainState: loadingState)
        let loadingMoreViewState = sut.reduce(domainState: loadingMoreState)
        let refreshingViewState = sut.reduce(domainState: refreshingState)

        #expect(loadingViewState.isLoading == true)
        #expect(loadingMoreViewState.isLoadingMore == true)
        #expect(refreshingViewState.isRefreshing == true)
    }

    // MARK: - Error State Tests (Consolidated)

    @Test("Reduce passes through error message including nil")
    func reducePassesThroughErrorMessage() {
        let errorState = makeDomainState(error: "Network error")
        let noErrorState = makeDomainState(breakingNews: Article.mockArticles, error: nil)

        let errorViewState = sut.reduce(domainState: errorState)
        let noErrorViewState = sut.reduce(domainState: noErrorState)

        #expect(errorViewState.errorMessage == "Network error")
        #expect(noErrorViewState.errorMessage == nil)
    }

    // MARK: - Empty State Tests (Consolidated)

    @Test("showEmptyState logic handles all conditions correctly")
    func showEmptyStateLogic() {
        // Empty state when no content and not loading
        let emptyState = makeDomainState()
        #expect(sut.reduce(domainState: emptyState).showEmptyState == true)

        // Not empty when loading
        let loadingState = makeDomainState(isLoading: true)
        #expect(sut.reduce(domainState: loadingState).showEmptyState == false)

        // Not empty when refreshing
        let refreshingState = makeDomainState(isRefreshing: true)
        #expect(sut.reduce(domainState: refreshingState).showEmptyState == false)

        // Not empty when has breaking news
        let withBreakingNews = makeDomainState(breakingNews: Article.mockArticles)
        #expect(sut.reduce(domainState: withBreakingNews).showEmptyState == false)

        // Not empty when has headlines
        let withHeadlines = makeDomainState(headlines: Article.mockArticles)
        #expect(sut.reduce(domainState: withHeadlines).showEmptyState == false)
    }

    // MARK: - Category Tabs Tests

    @Test("showCategoryTabs is true when followedTopics is not empty")
    func showCategoryTabsWhenFollowedTopicsNotEmpty() {
        let stateWithTopics = makeDomainState(followedTopics: [.technology, .business])
        let viewState = sut.reduce(domainState: stateWithTopics)

        #expect(viewState.showCategoryTabs == true)
        #expect(viewState.followedTopics.count == 2)
        #expect(viewState.followedTopics.contains(.technology))
        #expect(viewState.followedTopics.contains(.business))
    }

    @Test("showCategoryTabs is false when followedTopics is empty")
    func showCategoryTabsWhenFollowedTopicsEmpty() {
        let stateWithoutTopics = makeDomainState(followedTopics: [])
        let viewState = sut.reduce(domainState: stateWithoutTopics)

        #expect(viewState.showCategoryTabs == false)
        #expect(viewState.followedTopics.isEmpty)
    }

    @Test("selectedCategory is passed through correctly")
    func selectedCategoryPassedThrough() {
        let stateWithCategory = makeDomainState(
            selectedCategory: .technology,
            followedTopics: [.technology, .science]
        )
        let viewState = sut.reduce(domainState: stateWithCategory)

        #expect(viewState.selectedCategory == .technology)
    }

    @Test("selectedCategory nil represents All tab")
    func selectedCategoryNilRepresentsAllTab() {
        let stateAllTab = makeDomainState(
            selectedCategory: nil,
            followedTopics: [.technology, .science]
        )
        let viewState = sut.reduce(domainState: stateAllTab)

        #expect(viewState.selectedCategory == nil)
        #expect(viewState.showCategoryTabs == true)
    }

    @Test("followedTopics order is preserved")
    func followedTopicsOrderPreserved() {
        let orderedTopics: [NewsCategory] = [.science, .technology, .business, .health]
        let state = makeDomainState(followedTopics: orderedTopics)
        let viewState = sut.reduce(domainState: state)

        #expect(viewState.followedTopics == orderedTopics)
    }

    @Test("category tabs with all category types")
    func categoryTabsWithAllCategoryTypes() {
        let allCategories: [NewsCategory] = NewsCategory.allCases
        let state = makeDomainState(followedTopics: allCategories)
        let viewState = sut.reduce(domainState: state)

        #expect(viewState.showCategoryTabs == true)
        #expect(viewState.followedTopics.count == allCategories.count)
    }

    // MARK: - Read Article Tests

    @Test("isRead flag is set correctly on ArticleViewItems")
    func isReadFlagSetCorrectly() {
        let articles = Article.mockArticles
        let readIDs: Set<String> = [articles[0].id]
        let state = makeDomainState(
            headlines: articles,
            readArticleIDs: readIDs
        )
        let viewState = sut.reduce(domainState: state)

        #expect(viewState.headlines[0].isRead == true)
        #expect(viewState.headlines[1].isRead == false)
    }

    @Test("isRead flag defaults to false when readArticleIDs is empty")
    func isReadFlagDefaultsFalse() {
        let state = makeDomainState(
            headlines: Article.mockArticles,
            readArticleIDs: []
        )
        let viewState = sut.reduce(domainState: state)

        #expect(viewState.headlines.allSatisfy { !$0.isRead })
    }
}
