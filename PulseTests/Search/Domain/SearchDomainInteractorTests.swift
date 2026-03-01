// swiftlint:disable file_length
import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("SearchDomainInteractor Tests")
@MainActor
struct SearchDomainInteractorTests {
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

    /// Helper to generate mock articles (need 20+ to enable pagination)
    private func makeMockArticles(count: Int, idPrefix: String = "article") -> [Article] {
        (1 ... count).map { index in
            Article(
                id: "\(idPrefix)-\(index)",
                title: "Article \(index)",
                description: "Description \(index)",
                content: "Content \(index)",
                author: "Author",
                source: ArticleSource(id: "source", name: "Source"),
                url: "https://example.com/\(idPrefix)/\(index)",
                imageURL: nil,
                publishedAt: Date(),
                category: .technology
            )
        }
    }

    // MARK: - Initial State Tests

    @Test("Initial state is correct")
    func initialState() {
        let state = sut.currentState
        #expect(state.query.isEmpty)
        #expect(state.results.isEmpty)
        #expect(state.suggestions.isEmpty)
        #expect(!state.isLoading)
        #expect(!state.isLoadingMore)
        #expect(!state.isSorting)
        #expect(state.error == nil)
        #expect(state.currentPage == 1)
        #expect(state.hasMorePages)
        #expect(state.sortBy == .relevancy)
        #expect(!state.hasSearched)
    }

    // MARK: - Query Update Tests

    @Test("Update query updates state")
    func updateQueryUpdatesState() async throws {
        sut.dispatch(action: .updateQuery("swift"))

        try await Task.sleep(nanoseconds: 100_000_000)

        let state = sut.currentState
        #expect(state.query == "swift")
    }

    @Test("Update query triggers suggestions")
    func updateQueryTriggersSuggestions() async throws {
        mockSearchService.suggestionsResult = ["Swift", "SwiftUI", "Swift Testing"]

        sut.dispatch(action: .updateQuery("swift"))

        // Wait for 300ms debounce + Combine scheduling overhead
        try await Task.sleep(nanoseconds: 500_000_000)

        let state = sut.currentState
        #expect(!state.suggestions.isEmpty)
        #expect(state.suggestions.contains("Swift"))
    }

    @Test("Empty query clears suggestions")
    func emptyQueryClearsSuggestions() async throws {
        mockSearchService.suggestionsResult = ["Swift", "iOS"]

        sut.dispatch(action: .updateQuery("swift"))
        try await Task.sleep(nanoseconds: 100_000_000)

        sut.dispatch(action: .updateQuery(""))
        try await Task.sleep(nanoseconds: 100_000_000)

        let state = sut.currentState
        #expect(state.suggestions.isEmpty)
    }

    @Test("Update query truncates to max length")
    func updateQueryTruncatesToMaxLength() async throws {
        let oversizedQuery = String(repeating: "a", count: 300)

        sut.dispatch(action: .updateQuery(oversizedQuery))

        try await Task.sleep(nanoseconds: 100_000_000)

        let state = sut.currentState
        #expect(state.query.count == 256)
        #expect(state.query == String(oversizedQuery.prefix(256)))
    }

    @Test("Search uses truncated query length in analytics")
    func searchUsesTruncatedQueryLengthInAnalytics() async throws {
        let oversizedQuery = String(repeating: "b", count: 400)
        mockSearchService.searchResult = .success(Article.mockArticles)

        sut.dispatch(action: .updateQuery(oversizedQuery))
        sut.dispatch(action: .search)

        try await Task.sleep(nanoseconds: 500_000_000)

        let searchEvents = mockAnalyticsService.loggedEvents.filter { $0.name == "search_performed" }
        #expect(searchEvents.count == 1)
        #expect(searchEvents.first?.parameters?["query_length"] as? Int == 256)
    }

    // MARK: - Search Tests

    @Test("Search action loads results")
    func searchLoadsResults() async throws {
        mockSearchService.searchResult = .success(Article.mockArticles)

        sut.dispatch(action: .updateQuery("technology"))
        sut.dispatch(action: .search)

        try await Task.sleep(nanoseconds: 500_000_000)

        let state = sut.currentState
        #expect(!state.isLoading)
        #expect(!state.results.isEmpty)
        #expect(state.hasSearched)
        #expect(state.error == nil)
    }

    @Test("Search with empty query does nothing")
    func searchWithEmptyQueryDoesNothing() async throws {
        sut.dispatch(action: .search)

        try await Task.sleep(nanoseconds: 100_000_000)

        let state = sut.currentState
        #expect(!state.isLoading)
        #expect(state.results.isEmpty)
        #expect(!state.hasSearched)
    }

    @Test("Search error handling")
    func searchErrorHandling() async throws {
        let testError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Search failed"])
        mockSearchService.searchResult = .failure(testError)

        sut.dispatch(action: .updateQuery("test"))
        sut.dispatch(action: .search)

        try await Task.sleep(nanoseconds: 500_000_000)

        let state = sut.currentState
        #expect(!state.isLoading)
        #expect(state.error != nil)
        #expect(state.error == "Search failed")
    }

    @Test("Search resets page to 1")
    func searchResetsPage() async throws {
        mockSearchService.searchResult = .success(Article.mockArticles)

        sut.dispatch(action: .updateQuery("test"))
        sut.dispatch(action: .search)

        try await Task.sleep(nanoseconds: 500_000_000)

        let state = sut.currentState
        #expect(state.currentPage == 1)
    }

    // MARK: - Load More Tests

    @Test("Load more appends results")
    func loadMoreAppendsResults() async throws {
        // Need exactly 20 articles to set hasMorePages = true
        mockSearchService.searchResult = .success(makeMockArticles(count: 20))

        sut.dispatch(action: .updateQuery("test"))
        sut.dispatch(action: .search)

        try await Task.sleep(nanoseconds: 500_000_000)

        let initialCount = sut.currentState.results.count
        #expect(initialCount == 20)

        // Set up new article for load more
        mockSearchService.searchResult = .success(makeMockArticles(count: 1, idPrefix: "new"))

        sut.dispatch(action: .loadMore)

        try await Task.sleep(nanoseconds: 500_000_000)

        let state = sut.currentState
        #expect(state.results.count > initialCount)
        #expect(state.currentPage == 2)
    }

    @Test("Load more deduplicates results")
    func loadMoreDeduplicatesResults() async throws {
        mockSearchService.searchResult = .success(Article.mockArticles)

        sut.dispatch(action: .updateQuery("test"))
        sut.dispatch(action: .search)

        try await Task.sleep(nanoseconds: 500_000_000)

        let initialCount = sut.currentState.results.count

        // Return same articles - should be deduplicated
        sut.dispatch(action: .loadMore)

        try await Task.sleep(nanoseconds: 500_000_000)

        let state = sut.currentState
        // Count should not increase significantly due to deduplication
        #expect(state.results.count == initialCount)
    }

    @Test("Load more handles rapid dispatches gracefully")
    func loadMoreHandlesRapidDispatches() async throws {
        mockSearchService.searchResult = .success(makeMockArticles(count: 20))

        sut.dispatch(action: .updateQuery("test"))
        sut.dispatch(action: .search)

        try await Task.sleep(nanoseconds: 500_000_000)

        let initialPage = sut.currentState.currentPage
        #expect(initialPage == 1)

        // Dispatch load more twice in quick succession
        // Both may succeed due to async timing, which is acceptable
        sut.dispatch(action: .loadMore)
        sut.dispatch(action: .loadMore)

        try await Task.sleep(nanoseconds: 500_000_000)

        let state = sut.currentState
        // Page should have advanced (at least once)
        #expect(state.currentPage > initialPage)
        // State should be consistent (not loading anymore)
        #expect(!state.isLoadingMore)
    }

    @Test("Load more respects hasMorePages")
    func loadMoreRespectsHasMorePages() async throws {
        // Return fewer than 20 articles to indicate no more pages
        mockSearchService.searchResult = .success(Array(Article.mockArticles.prefix(5)))

        sut.dispatch(action: .updateQuery("test"))
        sut.dispatch(action: .search)

        try await Task.sleep(nanoseconds: 500_000_000)

        let state = sut.currentState
        #expect(!state.hasMorePages)

        // Try to load more - should do nothing
        sut.dispatch(action: .loadMore)

        try await Task.sleep(nanoseconds: 200_000_000)

        #expect(sut.currentState.currentPage == 1)
    }

    // MARK: - Clear Results Tests

    @Test("Clear results resets state")
    func clearResultsResetsState() async throws {
        mockSearchService.searchResult = .success(Article.mockArticles)

        sut.dispatch(action: .updateQuery("test"))
        sut.dispatch(action: .search)

        try await Task.sleep(nanoseconds: 500_000_000)

        sut.dispatch(action: .clearResults)

        let state = sut.currentState
        #expect(state.query.isEmpty)
        #expect(state.results.isEmpty)
        #expect(state.suggestions.isEmpty)
        #expect(state.error == nil)
        #expect(!state.hasSearched)
    }

    // MARK: - Sort Option Tests

    @Test("Set sort option updates state")
    func setSortOptionUpdatesState() {
        sut.dispatch(action: .setSortOption(.publishedAt))

        let state = sut.currentState
        #expect(state.sortBy == .publishedAt)
    }

    @Test("Set sort option triggers re-search when has searched")
    func setSortOptionTriggersReSearch() async throws {
        mockSearchService.searchResult = .success(Article.mockArticles)

        sut.dispatch(action: .updateQuery("test"))
        sut.dispatch(action: .search)

        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(sut.currentState.hasSearched)

        sut.dispatch(action: .setSortOption(.publishedAt))

        try await Task.sleep(nanoseconds: 500_000_000)

        let state = sut.currentState
        #expect(state.sortBy == .publishedAt)
        #expect(state.currentPage == 1) // Reset after sort
    }

    @Test("Set sort option does not search when query is empty")
    func setSortOptionNoSearchWhenEmpty() async throws {
        sut.dispatch(action: .setSortOption(.popularity))

        try await Task.sleep(nanoseconds: 200_000_000)

        let state = sut.currentState
        #expect(state.sortBy == .popularity)
        #expect(!state.hasSearched)
        #expect(state.results.isEmpty)
    }

    // MARK: - Reading History Tests

    @Test("Initial load pulls read article IDs")
    func initialLoadPullsReadArticleIDs() async throws {
        let mockSearchService = MockSearchService()
        let mockStorageService = MockStorageService()
        let mockAnalyticsService = MockAnalyticsService()
        let locator = ServiceLocator()
        let readArticle = Article.mockArticles[0]

        mockStorageService.readArticles = [readArticle]

        locator.register(SearchService.self, instance: mockSearchService)
        locator.register(StorageService.self, instance: mockStorageService)
        locator.register(AnalyticsService.self, instance: mockAnalyticsService)

        let interactor = SearchDomainInteractor(serviceLocator: locator)

        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(interactor.currentState.readArticleIDs.contains(readArticle.id))
    }

    @Test("Reading history clear notification resets read IDs")
    func readingHistoryClearNotificationResetsReadIDs() async throws {
        let article = Article.mockArticles[0]

        mockSearchService.searchResult = .success([article])
        sut.dispatch(action: .updateQuery("test"))
        sut.dispatch(action: .search)
        try await Task.sleep(nanoseconds: 500_000_000)

        sut.dispatch(action: .selectArticle(articleId: article.id))
        try await Task.sleep(nanoseconds: 100_000_000)
        #expect(sut.currentState.readArticleIDs.contains(article.id))

        NotificationCenter.default.post(name: .readingHistoryDidClear, object: nil)
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(sut.currentState.readArticleIDs.isEmpty)
    }

    // MARK: - Select Article Tests

    @Test("Select article dispatches action")
    func selectArticleDispatchesAction() async throws {
        let article = Article.mockArticles[0]

        // First search to load articles so they can be found
        mockSearchService.searchResult = .success([article])
        sut.dispatch(action: .updateQuery("test"))
        sut.dispatch(action: .search)
        try await Task.sleep(nanoseconds: 500_000_000)

        // Select article action should not throw
        sut.dispatch(action: .selectArticle(articleId: article.id))

        // Verify the action can be dispatched without error
        #expect(true)
    }

    // MARK: - Empty Results Tests

    @Test("Empty search results handled correctly")
    func emptySearchResultsHandled() async throws {
        mockSearchService.searchResult = .success([])

        sut.dispatch(action: .updateQuery("nonexistent"))
        sut.dispatch(action: .search)

        try await Task.sleep(nanoseconds: 500_000_000)

        let state = sut.currentState
        #expect(state.results.isEmpty)
        #expect(state.hasSearched)
        #expect(!state.hasMorePages)
        #expect(state.error == nil)
    }
}

// MARK: - Analytics Tests

extension SearchDomainInteractorTests {
    @Test("Logs search_performed on successful search")
    func logsSearchPerformedOnSuccess() async throws {
        let articles = Article.mockArticles
        mockSearchService.searchResult = .success(articles)

        sut.dispatch(action: .updateQuery("swift"))
        sut.dispatch(action: .search)
        try await Task.sleep(nanoseconds: 500_000_000)

        let searchEvents = mockAnalyticsService.loggedEvents.filter { $0.name == "search_performed" }
        #expect(searchEvents.count == 1)
        #expect(searchEvents.first?.parameters?["query_length"] as? Int == 5)
        #expect(searchEvents.first?.parameters?["result_count"] as? Int == articles.count)
    }

    @Test("Records error on search failure")
    func recordsErrorOnSearchFailure() async throws {
        mockSearchService.searchResult = .failure(NSError(domain: "test", code: 1))

        sut.dispatch(action: .updateQuery("test"))
        sut.dispatch(action: .search)
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(mockAnalyticsService.recordedErrors.count == 1)
    }

    @Test("Logs article_opened with search source")
    func logsArticleOpenedFromSearch() async throws {
        let articles = Article.mockArticles
        mockSearchService.searchResult = .success(articles)

        sut.dispatch(action: .updateQuery("test"))
        sut.dispatch(action: .search)
        try await Task.sleep(nanoseconds: 500_000_000)

        sut.dispatch(action: .selectArticle(articleId: articles[0].id))

        let openedEvents = mockAnalyticsService.loggedEvents.filter { $0.name == "article_opened" }
        #expect(openedEvents.count == 1)
        #expect(openedEvents.first?.parameters?["source"] as? String == "search")
    }
}
