import Foundation
@testable import Pulse
import Testing

@Suite("HomeViewStateReducer Tests")
struct HomeViewStateReducerTests {
    let sut = HomeViewStateReducer()

    // Helper to create domain state with defaults
    private func makeDomainState(
        breakingNews: [Article] = [],
        headlines: [Article] = [],
        isLoading: Bool = false,
        isLoadingMore: Bool = false,
        isRefreshing: Bool = false,
        error: String? = nil,
        currentPage: Int = 1,
        hasMorePages: Bool = true,
        hasLoadedInitialData: Bool = true
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
            hasLoadedInitialData: hasLoadedInitialData
        )
    }

    // MARK: - Basic Transformation Tests

    @Test("Reduce transforms breaking news to ArticleViewItems")
    func reduceTransformsBreakingNews() {
        let domainState = makeDomainState(breakingNews: Article.mockArticles)

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.breakingNews.count == Article.mockArticles.count)
        #expect(viewState.breakingNews[0].id == Article.mockArticles[0].id)
        #expect(viewState.breakingNews[0].title == Article.mockArticles[0].title)
    }

    @Test("Reduce transforms headlines to ArticleViewItems")
    func reduceTransformsHeadlines() {
        let domainState = makeDomainState(headlines: Article.mockArticles)

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.headlines.count == Article.mockArticles.count)
        #expect(viewState.headlines[0].id == Article.mockArticles[0].id)
    }

    // MARK: - Loading State Tests

    @Test("Reduce passes through isLoading state")
    func reducePassesThroughIsLoading() {
        let domainState = makeDomainState(isLoading: true)

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.isLoading == true)
    }

    @Test("Reduce passes through isLoadingMore state")
    func reducePassesThroughIsLoadingMore() {
        let domainState = makeDomainState(headlines: Article.mockArticles, isLoadingMore: true)

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.isLoadingMore == true)
    }

    @Test("Reduce passes through isRefreshing state")
    func reducePassesThroughIsRefreshing() {
        let domainState = makeDomainState(isRefreshing: true)

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.isRefreshing == true)
    }

    // MARK: - Error State Tests

    @Test("Reduce passes through error message")
    func reducePassesThroughErrorMessage() {
        let domainState = makeDomainState(error: "Network error")

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.errorMessage == "Network error")
    }

    @Test("Reduce handles nil error")
    func reduceHandlesNilError() {
        let domainState = makeDomainState(breakingNews: Article.mockArticles, error: nil)

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.errorMessage == nil)
    }

    // MARK: - Empty State Tests

    @Test("showEmptyState is true when not loading and no content")
    func showEmptyStateWhenNoContent() {
        let domainState = makeDomainState()

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.showEmptyState == true)
    }

    @Test("showEmptyState is false when loading")
    func showEmptyStateFalseWhenLoading() {
        let domainState = makeDomainState(isLoading: true)

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.showEmptyState == false)
    }

    @Test("showEmptyState is false when refreshing")
    func showEmptyStateFalseWhenRefreshing() {
        let domainState = makeDomainState(isRefreshing: true)

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.showEmptyState == false)
    }

    @Test("showEmptyState is false when has breaking news")
    func showEmptyStateFalseWithBreakingNews() {
        let domainState = makeDomainState(breakingNews: Article.mockArticles)

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.showEmptyState == false)
    }

    @Test("showEmptyState is false when has headlines")
    func showEmptyStateFalseWithHeadlines() {
        let domainState = makeDomainState(headlines: Article.mockArticles)

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.showEmptyState == false)
    }
}
