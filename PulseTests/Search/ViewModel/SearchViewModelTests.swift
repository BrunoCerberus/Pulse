import Testing
import Combine
import Foundation
@testable import Pulse

@Suite("SearchViewModel Tests")
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
    func testInitialViewState() {
        let state = sut.viewState
        #expect(state.query.isEmpty)
        #expect(state.results.isEmpty)
        #expect(state.suggestions.isEmpty)
        #expect(!state.isLoading)
        #expect(!state.showNoResults)
    }

    @Test("Query change updates state")
    func testQueryChange() async throws {
        sut.handle(event: .onQueryChanged("test"))

        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(sut.viewState.query == "test")
    }

    @Test("Search triggers loading")
    func testSearch() async throws {
        mockSearchService.searchResult = .success(Article.mockArticles)

        sut.handle(event: .onQueryChanged("swift"))
        sut.handle(event: .onSearch)

        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(!sut.viewState.isLoading)
    }

    @Test("Clear results resets state")
    func testClearResults() {
        sut.handle(event: .onQueryChanged("test"))
        sut.handle(event: .onClear)

        #expect(sut.viewState.query.isEmpty)
        #expect(sut.viewState.results.isEmpty)
    }

    @Test("Article tap sets selected article")
    func testArticleTap() {
        let article = Article.mockArticles[0]

        sut.handle(event: .onArticleTapped(article))

        #expect(sut.selectedArticle?.id == article.id)
    }

    @Test("Sort change updates sort option")
    func testSortChange() {
        sut.handle(event: .onSortChanged(.publishedAt))

        #expect(sut.viewState.sortOption == .publishedAt)
    }
}
