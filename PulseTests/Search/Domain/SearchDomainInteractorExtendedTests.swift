import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("SearchDomainInteractor Extended Tests")
@MainActor
struct SearchDomainInteractorExtendedTests {
    let mockSearchService: MockSearchService
    let mockStorageService: MockStorageService
    let mockAnalyticsService: MockAnalyticsService
    let serviceLocator: ServiceLocator
    let sut: SearchDomainInteractor

    init() {
        mockSearchService = MockSearchService()
        mockStorageService = MockStorageService()
        mockAnalyticsService = MockAnalyticsService()
        serviceLocator = ServiceLocator()

        serviceLocator.register(SearchService.self, instance: mockSearchService)
        serviceLocator.register(StorageService.self, instance: mockStorageService)
        serviceLocator.register(AnalyticsService.self, instance: mockAnalyticsService)

        sut = SearchDomainInteractor(serviceLocator: serviceLocator)
    }

    // MARK: - Share Article Tests

    @Test("Share article sets articleToShare")
    func shareArticleSetsState() async throws {
        let articles = Article.mockArticles
        mockSearchService.searchResult = .success(articles)

        sut.dispatch(action: .updateQuery("test"))
        sut.dispatch(action: .search)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        sut.dispatch(action: .shareArticle(articleId: articles[0].id))

        #expect(sut.currentState.articleToShare?.id == articles[0].id)
    }

    @Test("Share non-existent article does nothing")
    func shareNonExistentArticle() async throws {
        let articles = Article.mockArticles
        mockSearchService.searchResult = .success(articles)

        sut.dispatch(action: .updateQuery("test"))
        sut.dispatch(action: .search)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        sut.dispatch(action: .shareArticle(articleId: "non-existent"))

        #expect(sut.currentState.articleToShare == nil)
    }

    @Test("Clear article to share resets state")
    func clearArticleToShare() async throws {
        let articles = Article.mockArticles
        mockSearchService.searchResult = .success(articles)

        sut.dispatch(action: .updateQuery("test"))
        sut.dispatch(action: .search)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        sut.dispatch(action: .shareArticle(articleId: articles[0].id))
        #expect(sut.currentState.articleToShare != nil)

        sut.dispatch(action: .clearArticleToShare)
        #expect(sut.currentState.articleToShare == nil)
    }

    // MARK: - Bookmark Article Tests

    @Test("Bookmark article saves to storage")
    func bookmarkArticleSaves() async throws {
        let articles = Article.mockArticles
        mockSearchService.searchResult = .success(articles)

        sut.dispatch(action: .updateQuery("test"))
        sut.dispatch(action: .search)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        sut.dispatch(action: .bookmarkArticle(articleId: articles[0].id))
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(mockStorageService.bookmarkedArticles.contains(where: { $0.id == articles[0].id }))
    }

    @Test("Bookmark already bookmarked article removes it")
    func bookmarkAlreadyBookmarkedRemoves() async throws {
        let articles = Article.mockArticles
        mockSearchService.searchResult = .success(articles)
        mockStorageService.bookmarkedArticles = [articles[0]]

        sut.dispatch(action: .updateQuery("test"))
        sut.dispatch(action: .search)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        sut.dispatch(action: .bookmarkArticle(articleId: articles[0].id))
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(!mockStorageService.bookmarkedArticles.contains(where: { $0.id == articles[0].id }))
    }

    @Test("Bookmark non-existent article does nothing")
    func bookmarkNonExistentArticle() async throws {
        let articles = Article.mockArticles
        mockSearchService.searchResult = .success(articles)

        sut.dispatch(action: .updateQuery("test"))
        sut.dispatch(action: .search)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        let initialCount = mockStorageService.bookmarkedArticles.count
        sut.dispatch(action: .bookmarkArticle(articleId: "non-existent"))
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(mockStorageService.bookmarkedArticles.count == initialCount)
    }

    // MARK: - Select Article Tests

    @Test("Select article sets selectedArticle and marks as read")
    func selectArticleSetsStateAndMarksRead() async throws {
        let articles = Article.mockArticles
        mockSearchService.searchResult = .success(articles)

        sut.dispatch(action: .updateQuery("test"))
        sut.dispatch(action: .search)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        sut.dispatch(action: .selectArticle(articleId: articles[0].id))

        #expect(sut.currentState.selectedArticle?.id == articles[0].id)
        #expect(sut.currentState.readArticleIDs.contains(articles[0].id))
    }

    @Test("Clear selected article resets selection")
    func clearSelectedArticle() async throws {
        let articles = Article.mockArticles
        mockSearchService.searchResult = .success(articles)

        sut.dispatch(action: .updateQuery("test"))
        sut.dispatch(action: .search)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        sut.dispatch(action: .selectArticle(articleId: articles[0].id))
        #expect(sut.currentState.selectedArticle != nil)

        sut.dispatch(action: .clearSelectedArticle)
        #expect(sut.currentState.selectedArticle == nil)
    }

    @Test("Select non-existent article does nothing")
    func selectNonExistentArticle() async throws {
        let articles = Article.mockArticles
        mockSearchService.searchResult = .success(articles)

        sut.dispatch(action: .updateQuery("test"))
        sut.dispatch(action: .search)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        sut.dispatch(action: .selectArticle(articleId: "non-existent"))

        #expect(sut.currentState.selectedArticle == nil)
    }

    // MARK: - Sorted Search Tests

    @Test("Sort option change triggers re-search after prior search")
    func sortOptionTriggersResearch() async throws {
        let articles = Article.mockArticles
        mockSearchService.searchResult = .success(articles)

        sut.dispatch(action: .updateQuery("test"))
        sut.dispatch(action: .search)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(sut.currentState.hasSearched)

        sut.dispatch(action: .setSortOption(.publishedAt))
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(sut.currentState.sortBy == .publishedAt)
        #expect(sut.currentState.currentPage == 1)
        #expect(!sut.currentState.isSorting)
    }

    @Test("Sorted search error sets error state")
    func sortedSearchErrorSetsError() async throws {
        let articles = Article.mockArticles
        mockSearchService.searchResult = .success(articles)

        sut.dispatch(action: .updateQuery("test"))
        sut.dispatch(action: .search)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        // Now make search fail
        mockSearchService.searchResult = .failure(
            NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Sort failed"])
        )

        sut.dispatch(action: .setSortOption(.popularity))
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(sut.currentState.error == "Sort failed")
        #expect(!sut.currentState.isSorting)
    }

    // MARK: - Offline Error Tests

    @Test("Search offline error sets isOfflineError")
    func searchOfflineErrorSetsFlag() async throws {
        mockSearchService.searchResult = .failure(PulseError.offlineNoCache)

        sut.dispatch(action: .updateQuery("test"))
        sut.dispatch(action: .search)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(sut.currentState.isOfflineError)
        #expect(sut.currentState.error != nil)
    }

    @Test("Non-offline error does not set isOfflineError")
    func nonOfflineErrorDoesNotSetFlag() async throws {
        let urlError = URLError(.notConnectedToInternet)
        mockSearchService.searchResult = .failure(urlError)

        sut.dispatch(action: .updateQuery("test"))
        sut.dispatch(action: .search)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        // URLError is not PulseError, so isOfflineError should be false
        #expect(!sut.currentState.isOfflineError)
        #expect(sut.currentState.error != nil)
    }

    @Test("Successful search clears isOfflineError")
    func successfulSearchClearsOfflineError() async throws {
        // First cause offline error
        mockSearchService.searchResult = .failure(PulseError.offlineNoCache)
        sut.dispatch(action: .updateQuery("test"))
        sut.dispatch(action: .search)
        try await waitForStateUpdate(duration: TestWaitDuration.long)
        #expect(sut.currentState.isOfflineError)

        // Now succeed
        mockSearchService.searchResult = .success(Article.mockArticles)
        sut.dispatch(action: .search)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(!sut.currentState.isOfflineError)
        #expect(sut.currentState.error == nil)
    }

    // MARK: - Analytics Tests

    @Test("Share article logs analytics event")
    func shareArticleLogsEvent() async throws {
        let articles = Article.mockArticles
        mockSearchService.searchResult = .success(articles)

        sut.dispatch(action: .updateQuery("test"))
        sut.dispatch(action: .search)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        sut.dispatch(action: .shareArticle(articleId: articles[0].id))

        let shareEvents = mockAnalyticsService.loggedEvents.filter { $0.name == "article_shared" }
        #expect(shareEvents.count == 1)
    }

    @Test("Bookmark article logs bookmarked event")
    func bookmarkLogsEvent() async throws {
        let articles = Article.mockArticles
        mockSearchService.searchResult = .success(articles)

        sut.dispatch(action: .updateQuery("test"))
        sut.dispatch(action: .search)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        sut.dispatch(action: .bookmarkArticle(articleId: articles[0].id))
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        let bookmarkEvents = mockAnalyticsService.loggedEvents.filter { $0.name == "article_bookmarked" }
        #expect(bookmarkEvents.count == 1)
    }

    @Test("Unbookmark article logs unbookmarked event")
    func unbookmarkLogsEvent() async throws {
        let articles = Article.mockArticles
        mockSearchService.searchResult = .success(articles)
        mockStorageService.bookmarkedArticles = [articles[0]]

        sut.dispatch(action: .updateQuery("test"))
        sut.dispatch(action: .search)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        sut.dispatch(action: .bookmarkArticle(articleId: articles[0].id))
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        let unbookmarkEvents = mockAnalyticsService.loggedEvents.filter { $0.name == "article_unbookmarked" }
        #expect(unbookmarkEvents.count == 1)
    }

    // MARK: - Load More Error Tests

    @Test("Load more failure stops loading state")
    func loadMoreFailureStopsLoading() async throws {
        // Need 20 articles to enable hasMorePages
        let articles = (1 ... 20).map { index in
            Article(
                id: "article-\(index)",
                title: "Article \(index)",
                description: nil,
                content: nil,
                author: nil,
                source: ArticleSource(id: nil, name: "Source"),
                url: "https://example.com/\(index)",
                imageURL: nil,
                publishedAt: Date(),
                category: nil
            )
        }
        mockSearchService.searchResult = .success(articles)

        sut.dispatch(action: .updateQuery("test"))
        sut.dispatch(action: .search)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(sut.currentState.hasMorePages)

        mockSearchService.searchResult = .failure(NSError(domain: "test", code: 1))
        sut.dispatch(action: .loadMore)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(!sut.currentState.isLoadingMore)
    }
}
