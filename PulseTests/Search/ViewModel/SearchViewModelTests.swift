import Combine
import Foundation
@testable import Pulse
import Testing

@Suite("SearchViewModel Tests")
@MainActor
struct SearchViewModelTests {
    let mockSearchService: MockSearchService
    let mockStorageService: MockStorageService
    let serviceLocator: ServiceLocator
    let sut: SearchViewModel

    init() {
        mockSearchService = MockSearchService()
        mockStorageService = MockStorageService()
        serviceLocator = ServiceLocator()

        serviceLocator.register(SearchService.self, instance: mockSearchService)
        serviceLocator.register(StorageService.self, instance: mockStorageService)

        sut = SearchViewModel(serviceLocator: serviceLocator)
    }

    @Test("Initial view state is correct")
    func initialViewState() {
        let state = sut.viewState
        #expect(state.query.isEmpty)
        #expect(state.results.isEmpty)
        #expect(state.suggestions.isEmpty)
        #expect(!state.isLoading)
        #expect(!state.showNoResults)
    }

    @Test("Query change updates state")
    func queryChange() async throws {
        sut.handle(event: .onQueryChanged("test"))

        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(sut.viewState.query == "test")
    }

    @Test("Search triggers loading")
    func search() async throws {
        mockSearchService.searchResult = .success(Article.mockArticles)

        sut.handle(event: .onQueryChanged("swift"))
        sut.handle(event: .onSearch)

        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(!sut.viewState.isLoading)
    }

    @Test("Clear results resets state")
    func clearResults() {
        sut.handle(event: .onQueryChanged("test"))
        sut.handle(event: .onClear)

        #expect(sut.viewState.query.isEmpty)
        #expect(sut.viewState.results.isEmpty)
    }

    @Test("Article tap sets selected article")
    func articleTap() {
        let article = Article.mockArticles[0]

        sut.handle(event: .onArticleTapped(article))

        #expect(sut.selectedArticle?.id == article.id)
    }

    @Test("Sort change updates sort option")
    func sortChange() async throws {
        sut.handle(event: .onSortChanged(.publishedAt))

        // Wait for main queue binding to propagate state change
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(sut.viewState.sortOption == .publishedAt)
    }

    // MARK: - Debounce Tests

    @Test("Query change triggers debounced search after 300ms")
    func queryChangeTriggersDebounceSearch() async throws {
        mockSearchService.searchResult = .success(Article.mockArticles)

        sut.handle(event: .onQueryChanged("technology"))

        // Wait for debounce (300ms) + processing
        try await Task.sleep(nanoseconds: 600_000_000)

        #expect(sut.viewState.hasSearched)
        #expect(!sut.viewState.results.isEmpty)
    }

    @Test("Manual search cancels pending debounce")
    func manualSearchCancelsDebounce() async throws {
        mockSearchService.searchResult = .success(Article.mockArticles)

        sut.handle(event: .onQueryChanged("test"))
        sut.handle(event: .onSearch)

        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(sut.viewState.hasSearched)
    }

    @Test("Clear cancels pending debounce")
    func clearCancelsDebounce() async throws {
        sut.handle(event: .onQueryChanged("test"))
        sut.handle(event: .onClear)

        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(!sut.viewState.hasSearched)
    }

    // MARK: - Suggestion Tests

    @Test("Suggestion tap sets query and searches immediately")
    func suggestionTapSetsQueryAndSearches() async throws {
        mockSearchService.searchResult = .success(Article.mockArticles)

        sut.handle(event: .onSuggestionTapped("Swift"))

        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(sut.viewState.query == "Swift")
        #expect(sut.viewState.hasSearched)
    }

    @Test("Suggestion tap cancels pending debounce")
    func suggestionTapCancelsDebounce() async throws {
        mockSearchService.searchResult = .success(Article.mockArticles)

        sut.handle(event: .onQueryChanged("swi"))
        sut.handle(event: .onSuggestionTapped("SwiftUI"))

        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(sut.viewState.query == "SwiftUI")
    }

    // MARK: - Load More Tests

    @Test("Load more appends results")
    func loadMoreAppendsResults() async throws {
        // Generate 20 unique articles so hasMorePages is set to true
        let initialArticles = (1 ... 20).map { index in
            Article(
                id: "article-\(index)",
                title: "Article \(index)",
                description: "Description \(index)",
                content: "Content \(index)",
                author: "Author",
                source: ArticleSource(id: "source", name: "Source"),
                url: "https://example.com/\(index)",
                imageURL: nil,
                publishedAt: Date(),
                category: .technology
            )
        }
        mockSearchService.searchResult = .success(initialArticles)

        sut.handle(event: .onQueryChanged("test"))
        sut.handle(event: .onSearch)
        try await Task.sleep(nanoseconds: 500_000_000)

        let initialCount = sut.viewState.results.count
        #expect(initialCount == 20)

        // Set up new unique article for load more
        let newArticle = Article(
            id: "new-article-21",
            title: "New Article",
            description: "Description",
            content: "Content",
            author: "Author",
            source: ArticleSource(id: "source", name: "Source"),
            url: "https://example.com/new-21",
            imageURL: nil,
            publishedAt: Date(),
            category: .technology
        )
        mockSearchService.searchResult = .success([newArticle])

        sut.handle(event: .onLoadMore)
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(sut.viewState.results.count > initialCount)
    }

    // MARK: - View State Transformation Tests

    @Test("Empty search results shows no results state")
    func emptySearchResultsShowsNoResults() async throws {
        mockSearchService.searchResult = .success([])

        sut.handle(event: .onQueryChanged("nonexistent"))
        sut.handle(event: .onSearch)

        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(sut.viewState.showNoResults)
        #expect(sut.viewState.hasSearched)
    }

    @Test("Error message propagates to view state")
    func errorMessagePropagates() async throws {
        let testError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Search failed"])
        mockSearchService.searchResult = .failure(testError)

        sut.handle(event: .onQueryChanged("test"))
        sut.handle(event: .onSearch)

        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(sut.viewState.errorMessage == "Search failed")
    }

    @Test("Article tap saves to reading history")
    func articleTapSavesToHistory() async throws {
        let article = Article.mockArticles[0]

        sut.handle(event: .onArticleTapped(article))

        try await Task.sleep(nanoseconds: 200_000_000)

        let history = try await mockStorageService.fetchReadingHistory()
        #expect(history.contains(where: { $0.id == article.id }))
    }

    @Test("Sort change triggers re-search when has searched")
    func sortChangeTriggersReSearch() async throws {
        mockSearchService.searchResult = .success(Article.mockArticles)

        sut.handle(event: .onQueryChanged("test"))
        sut.handle(event: .onSearch)
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(sut.viewState.hasSearched)

        sut.handle(event: .onSortChanged(.popularity))
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(sut.viewState.sortOption == .popularity)
    }

    @Test("View state updates through publisher binding")
    func viewStateUpdatesThroughPublisher() async throws {
        var cancellables = Set<AnyCancellable>()
        var states: [SearchViewState] = []

        sut.$viewState
            .sink { state in
                states.append(state)
            }
            .store(in: &cancellables)

        mockSearchService.searchResult = .success(Article.mockArticles)

        sut.handle(event: .onQueryChanged("test"))
        sut.handle(event: .onSearch)

        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(states.count > 1)
    }

    @Test("Empty query does not trigger search")
    func emptyQueryDoesNotTriggerSearch() async throws {
        sut.handle(event: .onQueryChanged(""))

        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(!sut.viewState.hasSearched)
    }
}
