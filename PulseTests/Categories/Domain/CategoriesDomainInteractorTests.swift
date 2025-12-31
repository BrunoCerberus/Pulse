import Combine
import Foundation
@testable import Pulse
import Testing

@Suite("CategoriesDomainInteractor Tests")
@MainActor
struct CategoriesDomainInteractorTests {
    let mockCategoriesService: MockCategoriesService
    let mockStorageService: MockStorageService
    let serviceLocator: ServiceLocator
    let sut: CategoriesDomainInteractor

    init() {
        mockCategoriesService = MockCategoriesService()
        mockStorageService = MockStorageService()
        serviceLocator = ServiceLocator()

        serviceLocator.register(CategoriesService.self, instance: mockCategoriesService)
        serviceLocator.register(StorageService.self, instance: mockStorageService)

        sut = CategoriesDomainInteractor(serviceLocator: serviceLocator)
    }

    // Helper to generate mock articles (need 20+ to enable pagination)
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
        #expect(state.selectedCategory == nil)
        #expect(state.articles.isEmpty)
        #expect(!state.isLoading)
        #expect(!state.isLoadingMore)
        #expect(!state.isRefreshing)
        #expect(state.error == nil)
        #expect(state.currentPage == 1)
        #expect(state.hasMorePages)
        #expect(!state.hasLoadedInitialData)
    }

    // MARK: - Select Category Tests

    @Test("Select category loads articles")
    func selectCategoryLoadsArticles() async throws {
        mockCategoriesService.articlesResult = .success(Article.mockArticles)

        sut.dispatch(action: .selectCategory(.technology))

        try await Task.sleep(nanoseconds: 500_000_000)

        let state = sut.currentState
        #expect(state.selectedCategory == .technology)
        #expect(!state.isLoading)
        #expect(!state.articles.isEmpty)
        #expect(state.hasLoadedInitialData)
        #expect(state.error == nil)
    }

    @Test("Select same category skips reload")
    func selectSameCategorySkipsReload() async throws {
        mockCategoriesService.articlesResult = .success(Article.mockArticles)

        // First selection
        sut.dispatch(action: .selectCategory(.technology))
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(sut.currentState.hasLoadedInitialData)
        let firstLoadArticles = sut.currentState.articles

        // Second selection of same category - should skip
        sut.dispatch(action: .selectCategory(.technology))
        try await Task.sleep(nanoseconds: 300_000_000)

        // Articles should be the same (not reloaded)
        #expect(sut.currentState.articles == firstLoadArticles)
    }

    @Test("Select different category clears and reloads")
    func selectDifferentCategoryClearsAndReloads() async throws {
        mockCategoriesService.articlesResult = .success(Article.mockArticles)

        // First selection
        sut.dispatch(action: .selectCategory(.technology))
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(sut.currentState.selectedCategory == .technology)

        // Track states
        var cancellables = Set<AnyCancellable>()
        var articleCounts: [Int] = []

        sut.statePublisher
            .map(\.articles.count)
            .sink { count in
                articleCounts.append(count)
            }
            .store(in: &cancellables)

        // Different category - should clear and reload
        sut.dispatch(action: .selectCategory(.sports))
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(sut.currentState.selectedCategory == .sports)
        // Should have cleared to 0 at some point
        #expect(articleCounts.contains(0))
    }

    @Test("Select category sets loading state")
    func selectCategorySetsLoadingState() async throws {
        var cancellables = Set<AnyCancellable>()
        var loadingStates: [Bool] = []

        sut.statePublisher
            .map(\.isLoading)
            .sink { isLoading in
                loadingStates.append(isLoading)
            }
            .store(in: &cancellables)

        mockCategoriesService.articlesResult = .success(Article.mockArticles)

        sut.dispatch(action: .selectCategory(.business))

        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(loadingStates.contains(true))
        #expect(loadingStates.last == false)
    }

    @Test("Select category handles error")
    func selectCategoryHandlesError() async throws {
        let testError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Category error"])
        mockCategoriesService.articlesResult = .failure(testError)

        sut.dispatch(action: .selectCategory(.health))

        try await Task.sleep(nanoseconds: 500_000_000)

        let state = sut.currentState
        #expect(!state.isLoading)
        #expect(state.error != nil)
        #expect(state.error == "Category error")
    }

    @Test("Select category resets page to 1")
    func selectCategoryResetsPage() async throws {
        mockCategoriesService.articlesResult = .success(makeMockArticles(count: 20))

        sut.dispatch(action: .selectCategory(.science))
        try await Task.sleep(nanoseconds: 500_000_000)

        sut.dispatch(action: .loadMore)
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(sut.currentState.currentPage == 2)

        // Select different category - should reset page
        sut.dispatch(action: .selectCategory(.entertainment))
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(sut.currentState.currentPage == 1)
    }

    // MARK: - Select Article Tests

    @Test("Select article saves to reading history")
    func selectArticleSavesToHistory() async throws {
        let article = Article.mockArticles[0]

        sut.dispatch(action: .selectArticle(article))

        try await Task.sleep(nanoseconds: 200_000_000)

        let history = try await mockStorageService.fetchReadingHistory()
        #expect(history.contains(where: { $0.id == article.id }))
    }

    // MARK: - All Categories Tests

    @Test("All news categories can be selected")
    func allCategoriesCanBeSelected() async throws {
        mockCategoriesService.articlesResult = .success(Article.mockArticles)

        for category in NewsCategory.allCases {
            sut.dispatch(action: .selectCategory(category))
            try await Task.sleep(nanoseconds: 300_000_000)

            let state = sut.currentState
            #expect(state.selectedCategory == category)
            #expect(state.hasLoadedInitialData)
        }
    }
}
