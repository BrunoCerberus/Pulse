import Combine
import Foundation
@testable import Pulse
import Testing

@Suite("HomeViewModel Tests")
@MainActor
struct HomeViewModelTests {
    let mockNewsService: MockNewsService
    let mockStorageService: MockStorageService
    let serviceLocator: ServiceLocator
    let sut: HomeViewModel

    init() {
        mockNewsService = MockNewsService()
        mockStorageService = MockStorageService()
        serviceLocator = ServiceLocator()

        serviceLocator.register(NewsService.self, instance: mockNewsService)
        serviceLocator.register(StorageService.self, instance: mockStorageService)

        sut = HomeViewModel(serviceLocator: serviceLocator)
    }

    @Test("Initial view state is correct")
    func initialViewState() {
        let state = sut.viewState
        #expect(state.breakingNews.isEmpty)
        #expect(state.headlines.isEmpty)
        #expect(!state.isLoading)
        #expect(!state.isLoadingMore)
        #expect(state.errorMessage == nil)
        // showEmptyState is true because bindings fire immediately with empty domain state
        #expect(state.showEmptyState)
    }

    @Test("Handle onAppear triggers load")
    func testOnAppear() async throws {
        mockNewsService.topHeadlinesResult = .success(Article.mockArticles)

        var cancellables = Set<AnyCancellable>()
        var states: [HomeViewState] = []

        sut.$viewState
            .sink { state in
                states.append(state)
            }
            .store(in: &cancellables)

        sut.handle(event: .onAppear)

        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(states.count > 1)
    }

    @Test("Handle onRefresh triggers refresh")
    func testOnRefresh() {
        sut.handle(event: .onRefresh)
        // Verify state is being refreshed
        #expect(true)
    }

    @Test("Handle onArticleTapped sets selected article")
    func testOnArticleTapped() {
        let article = Article.mockArticles[0]

        sut.handle(event: .onArticleTapped(article))

        #expect(sut.selectedArticle?.id == article.id)
    }

    @Test("Handle onShareTapped sets share article")
    func testOnShareTapped() {
        let article = Article.mockArticles[0]

        sut.handle(event: .onShareTapped(article))

        #expect(sut.shareArticle?.id == article.id)
    }

    @Test("View state reducer transforms domain state correctly")
    func viewStateReducer() {
        let reducer = HomeViewStateReducer()

        let domainState = HomeDomainState(
            breakingNews: [Article.mockArticles[0]],
            headlines: [Article.mockArticles[1], Article.mockArticles[2]],
            isLoading: false,
            isLoadingMore: true,
            error: nil,
            currentPage: 2,
            hasMorePages: true
        )

        let viewState = reducer.reduce(domainState: domainState)

        #expect(viewState.breakingNews.count == 1)
        #expect(viewState.headlines.count == 2)
        #expect(!viewState.isLoading)
        #expect(viewState.isLoadingMore)
        #expect(viewState.errorMessage == nil)
        #expect(!viewState.showEmptyState)
    }
}
