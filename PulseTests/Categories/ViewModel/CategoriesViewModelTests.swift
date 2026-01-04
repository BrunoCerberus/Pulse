import Combine
import Foundation
@testable import Pulse
import Testing

@Suite("CategoriesViewModel Tests")
@MainActor
struct CategoriesViewModelTests {
    let mockCategoriesService: MockCategoriesService
    let mockStorageService: MockStorageService
    let serviceLocator: ServiceLocator
    let sut: CategoriesViewModel

    init() {
        mockCategoriesService = MockCategoriesService()
        mockStorageService = MockStorageService()
        serviceLocator = ServiceLocator()

        serviceLocator.register(CategoriesService.self, instance: mockCategoriesService)
        serviceLocator.register(StorageService.self, instance: mockStorageService)

        sut = CategoriesViewModel(serviceLocator: serviceLocator)
    }

    @Test("Initial view state is correct")
    func initialViewState() {
        let state = sut.viewState
        #expect(state.categories.count == NewsCategory.allCases.count)
        #expect(state.selectedCategory == nil)
        #expect(state.articles.isEmpty)
        #expect(!state.isLoading)
        #expect(!state.isLoadingMore)
        #expect(!state.isRefreshing)
        #expect(state.errorMessage == nil)
        #expect(!state.showEmptyState)
        #expect(state.selectedArticle == nil)
    }

    @Test("Handle onCategorySelected triggers load")
    func testOnCategorySelected() async throws {
        mockCategoriesService.categoryArticlesResult = .success(Article.mockArticles)

        var cancellables = Set<AnyCancellable>()
        var states: [CategoriesViewState] = []

        sut.$viewState
            .sink { state in
                states.append(state)
            }
            .store(in: &cancellables)

        sut.handle(event: .onCategorySelected(.technology))

        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(sut.viewState.selectedCategory == .technology)
        #expect(states.count > 1)
    }

    @Test("Handle onRefresh triggers refresh")
    func testOnRefresh() async throws {
        // First select a category
        mockCategoriesService.categoryArticlesResult = .success(Article.mockArticles)
        sut.handle(event: .onCategorySelected(.business))
        try await Task.sleep(nanoseconds: 500_000_000)

        var cancellables = Set<AnyCancellable>()
        var states: [CategoriesViewState] = []

        sut.$viewState
            .sink { state in
                states.append(state)
            }
            .store(in: &cancellables)

        sut.handle(event: .onRefresh)

        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(states.count > 1)
    }

    @Test("Handle onLoadMore triggers load more")
    func testOnLoadMore() async throws {
        // First select category and load initial articles
        mockCategoriesService.categoryArticlesResult = .success(Article.mockArticles)
        sut.handle(event: .onCategorySelected(.technology))
        try await Task.sleep(nanoseconds: 500_000_000)

        let initialCount = sut.viewState.articles.count

        // Set up new article for load more
        let newArticle = Article(
            id: "new-article",
            title: "New Article",
            description: "Description",
            content: "Content",
            author: "Author",
            source: ArticleSource(id: "source", name: "Source"),
            url: "https://example.com/new",
            imageURL: nil,
            publishedAt: Date(),
            category: .technology
        )
        mockCategoriesService.categoryArticlesResult = .success([newArticle])

        sut.handle(event: .onLoadMore)
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(sut.viewState.articles.count >= initialCount)
    }

    @Test("Handle onArticleTapped sets selected article")
    func testOnArticleTapped() async throws {
        let article = Article.mockArticles[0]

        // First select category and load articles
        mockCategoriesService.categoryArticlesResult = .success([article])
        sut.handle(event: .onCategorySelected(.technology))
        try await Task.sleep(nanoseconds: 500_000_000)

        sut.handle(event: .onArticleTapped(articleId: article.id))

        // Wait for Combine pipeline to propagate state
        try await Task.sleep(nanoseconds: 50_000_000)

        #expect(sut.viewState.selectedArticle?.id == article.id)
    }

    @Test("Handle onArticleNavigated clears selected article")
    func testOnArticleNavigated() async throws {
        let article = Article.mockArticles[0]

        // First select category, load and select an article
        mockCategoriesService.categoryArticlesResult = .success([article])
        sut.handle(event: .onCategorySelected(.technology))
        try await Task.sleep(nanoseconds: 500_000_000)

        sut.handle(event: .onArticleTapped(articleId: article.id))
        try await Task.sleep(nanoseconds: 50_000_000)

        #expect(sut.viewState.selectedArticle != nil)

        sut.handle(event: .onArticleNavigated)
        try await Task.sleep(nanoseconds: 50_000_000)

        #expect(sut.viewState.selectedArticle == nil)
    }

    @Test("View state shows empty state when category selected but no articles")
    func testShowEmptyState() async throws {
        mockCategoriesService.categoryArticlesResult = .success([])

        sut.handle(event: .onCategorySelected(.technology))
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(sut.viewState.showEmptyState)
        #expect(sut.viewState.selectedCategory == .technology)
    }

    @Test("View state does not show empty state when no category selected")
    func noEmptyStateWithoutCategory() async throws {
        let state = sut.viewState
        #expect(!state.showEmptyState)
        #expect(state.selectedCategory == nil)
    }

    @Test("Error message propagates to view state")
    func testErrorMessage() async throws {
        let testError = NSError(
            domain: "test",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Category loading failed"]
        )
        mockCategoriesService.categoryArticlesResult = .failure(testError)

        sut.handle(event: .onCategorySelected(.business))
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(sut.viewState.errorMessage == "Category loading failed")
    }

    @Test("Switching categories updates state")
    func switchingCategories() async throws {
        mockCategoriesService.categoryArticlesResult = .success(Article.mockArticles)

        // Select first category
        sut.handle(event: .onCategorySelected(.technology))
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(sut.viewState.selectedCategory == .technology)

        // Switch to different category
        sut.handle(event: .onCategorySelected(.business))
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(sut.viewState.selectedCategory == .business)
    }

    @Test("View state reducer transforms domain state correctly")
    func viewStateTransformation() async throws {
        mockCategoriesService.categoryArticlesResult = .success(Article.mockArticles)

        sut.handle(event: .onCategorySelected(.science))
        try await Task.sleep(nanoseconds: 500_000_000)

        let state = sut.viewState
        #expect(state.selectedCategory == .science)
        #expect(!state.articles.isEmpty)
        #expect(!state.isLoading)
        #expect(!state.showEmptyState)
    }

    @Test("View state updates through publisher binding")
    func publisherBinding() async throws {
        var cancellables = Set<AnyCancellable>()
        var states: [CategoriesViewState] = []

        sut.$viewState
            .sink { state in
                states.append(state)
            }
            .store(in: &cancellables)

        mockCategoriesService.categoryArticlesResult = .success(Article.mockArticles)

        sut.handle(event: .onCategorySelected(.health))
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(states.count > 1)
    }

    @Test("Loading states are correctly reflected")
    func testLoadingStates() async throws {
        var cancellables = Set<AnyCancellable>()
        var loadingStates: [Bool] = []

        sut.$viewState
            .map(\.isLoading)
            .sink { isLoading in
                loadingStates.append(isLoading)
            }
            .store(in: &cancellables)

        mockCategoriesService.categoryArticlesResult = .success(Article.mockArticles)

        sut.handle(event: .onCategorySelected(.sports))
        try await Task.sleep(nanoseconds: 500_000_000)

        // Should have at least initial state (false) and loading state (true)
        #expect(loadingStates.count >= 2)
    }

    @Test("All categories are available in view state")
    func allCategoriesAvailable() {
        let state = sut.viewState
        #expect(state.categories.contains(.world))
        #expect(state.categories.contains(.business))
        #expect(state.categories.contains(.technology))
        #expect(state.categories.contains(.science))
        #expect(state.categories.contains(.health))
        #expect(state.categories.contains(.sports))
        #expect(state.categories.contains(.entertainment))
    }
}
