import Combine
import Foundation
@testable import Pulse
import Testing

/// Tests for CategoriesViewModel covering:
/// - Initial state with all available categories
/// - Category selection and article loading
/// - Refresh and load more functionality
/// - Article selection and navigation
/// - Empty state handling
/// - Error handling (category load, load more, refresh, recovery)
/// - Publisher binding and state transformation
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
        mockCategoriesService.articlesResult = .success(Article.mockArticles)

        var cancellables = Set<AnyCancellable>()
        var states: [CategoriesViewState] = []

        sut.$viewState
            .sink { state in
                states.append(state)
            }
            .store(in: &cancellables)

        sut.handle(event: .onCategorySelected(.technology))

        try await waitForStateUpdate()

        #expect(sut.viewState.selectedCategory == .technology)
        #expect(states.count > 1)
    }

    @Test("Handle onRefresh triggers refresh")
    func testOnRefresh() async throws {
        // First select a category
        mockCategoriesService.articlesResult = .success(Article.mockArticles)
        sut.handle(event: .onCategorySelected(.business))
        try await waitForStateUpdate()

        var cancellables = Set<AnyCancellable>()
        var states: [CategoriesViewState] = []

        sut.$viewState
            .sink { state in
                states.append(state)
            }
            .store(in: &cancellables)

        sut.handle(event: .onRefresh)

        try await waitForStateUpdate()

        #expect(states.count > 1)
    }

    @Test("Handle onLoadMore triggers load more")
    func testOnLoadMore() async throws {
        // First select category and load initial articles
        mockCategoriesService.articlesResult = .success(Article.mockArticles)
        sut.handle(event: .onCategorySelected(.technology))
        try await waitForStateUpdate()

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
        try await waitForStateUpdate()

        #expect(sut.viewState.articles.count >= initialCount)
    }

    @Test("Handle onArticleTapped sets selected article")
    func testOnArticleTapped() async throws {
        let article = Article.mockArticles[0]

        // First select category and load articles
        mockCategoriesService.categoryArticlesResult = .success([article])
        sut.handle(event: .onCategorySelected(.technology))
        try await waitForStateUpdate()

        sut.handle(event: .onArticleTapped(articleId: article.id))

        // Wait for Combine pipeline to propagate state
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        #expect(sut.viewState.selectedArticle?.id == article.id)
    }

    @Test("Handle onArticleNavigated clears selected article")
    func testOnArticleNavigated() async throws {
        let article = Article.mockArticles[0]

        // First select category, load and select an article
        mockCategoriesService.categoryArticlesResult = .success([article])
        sut.handle(event: .onCategorySelected(.technology))
        try await waitForStateUpdate()

        sut.handle(event: .onArticleTapped(articleId: article.id))
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        #expect(sut.viewState.selectedArticle != nil)

        sut.handle(event: .onArticleNavigated)
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        #expect(sut.viewState.selectedArticle == nil)
    }

    @Test("View state shows empty state when category selected but no articles")
    func testShowEmptyState() async throws {
        mockCategoriesService.articlesResult = .success([])

        sut.handle(event: .onCategorySelected(.technology))
        try await waitForStateUpdate()

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
        mockCategoriesService.articlesResult = .failure(testError)

        sut.handle(event: .onCategorySelected(.business))
        try await waitForStateUpdate()

        #expect(sut.viewState.errorMessage == "Category loading failed")
    }

    @Test("Switching categories updates state")
    func switchingCategories() async throws {
        mockCategoriesService.articlesResult = .success(Article.mockArticles)

        // Select first category
        sut.handle(event: .onCategorySelected(.technology))
        try await waitForStateUpdate()

        #expect(sut.viewState.selectedCategory == .technology)

        // Switch to different category
        sut.handle(event: .onCategorySelected(.business))
        try await waitForStateUpdate()

        #expect(sut.viewState.selectedCategory == .business)
    }

    @Test("View state reducer transforms domain state correctly")
    func viewStateTransformation() async throws {
        mockCategoriesService.articlesResult = .success(Article.mockArticles)

        sut.handle(event: .onCategorySelected(.science))
        try await waitForStateUpdate()

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

        mockCategoriesService.articlesResult = .success(Article.mockArticles)

        sut.handle(event: .onCategorySelected(.health))
        try await waitForStateUpdate()

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

        mockCategoriesService.articlesResult = .success(Article.mockArticles)

        sut.handle(event: .onCategorySelected(.sports))
        try await waitForStateUpdate()

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

    // MARK: - Error Path Tests

    @Test("Error during load more shows error message")
    func errorDuringLoadMore() async throws {
        // First select category and load articles successfully
        mockCategoriesService.articlesResult = .success(Article.mockArticles)
        sut.handle(event: .onCategorySelected(.technology))
        try await waitForStateUpdate()

        // Now simulate error during load more
        let loadMoreError = NSError(
            domain: "test",
            code: 2,
            userInfo: [NSLocalizedDescriptionKey: "Load more failed"]
        )
        mockCategoriesService.articlesResult = .failure(loadMoreError)

        sut.handle(event: .onLoadMore)
        try await waitForStateUpdate()

        #expect(sut.viewState.errorMessage == "Load more failed")
    }

    @Test("Error during refresh shows error message")
    func errorDuringRefresh() async throws {
        // First select category and load articles
        mockCategoriesService.articlesResult = .success(Article.mockArticles)
        sut.handle(event: .onCategorySelected(.business))
        try await waitForStateUpdate()

        #expect(!sut.viewState.articles.isEmpty)

        // Now simulate error during refresh
        let refreshError = NSError(
            domain: "test",
            code: 3,
            userInfo: [NSLocalizedDescriptionKey: "Refresh failed"]
        )
        mockCategoriesService.articlesResult = .failure(refreshError)

        sut.handle(event: .onRefresh)
        try await waitForStateUpdate()

        #expect(sut.viewState.errorMessage == "Refresh failed")
    }

    @Test("Error recovery: success after error clears error message")
    func errorRecovery() async throws {
        // First trigger an error when selecting category
        let initialError = NSError(
            domain: "test",
            code: 4,
            userInfo: [NSLocalizedDescriptionKey: "Category load failed"]
        )
        mockCategoriesService.articlesResult = .failure(initialError)

        sut.handle(event: .onCategorySelected(.science))
        try await waitForStateUpdate()

        #expect(sut.viewState.errorMessage == "Category load failed")

        // Now recover with successful load
        mockCategoriesService.articlesResult = .success(Article.mockArticles)

        sut.handle(event: .onRefresh)
        try await waitForStateUpdate()

        #expect(sut.viewState.errorMessage == nil)
        #expect(!sut.viewState.articles.isEmpty)
    }

    @Test("Switching categories after error clears error state")
    func switchingCategoriesAfterError() async throws {
        // First trigger an error
        let error = NSError(
            domain: "test",
            code: 5,
            userInfo: [NSLocalizedDescriptionKey: "Technology load failed"]
        )
        mockCategoriesService.articlesResult = .failure(error)

        sut.handle(event: .onCategorySelected(.technology))
        try await waitForStateUpdate()

        #expect(sut.viewState.errorMessage != nil)

        // Switch to different category with successful load
        mockCategoriesService.articlesResult = .success(Article.mockArticles)

        sut.handle(event: .onCategorySelected(.business))
        try await waitForStateUpdate()

        #expect(sut.viewState.errorMessage == nil)
        #expect(sut.viewState.selectedCategory == .business)
    }

    // MARK: - Service Integration Tests

    @Test("ViewModel handles network timeout errors gracefully")
    func networkTimeoutError() async throws {
        let timeoutError = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorTimedOut,
            userInfo: [NSLocalizedDescriptionKey: "The request timed out."]
        )
        mockCategoriesService.articlesResult = .failure(timeoutError)

        sut.handle(event: .onCategorySelected(.technology))
        try await waitForStateUpdate()

        #expect(sut.viewState.errorMessage == "The request timed out.")
        #expect(!sut.viewState.isLoading)
    }

    @Test("ViewModel handles no internet connection errors")
    func noInternetError() async throws {
        let noConnectionError = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorNotConnectedToInternet,
            userInfo: [NSLocalizedDescriptionKey: "The Internet connection appears to be offline."]
        )
        mockCategoriesService.articlesResult = .failure(noConnectionError)

        sut.handle(event: .onCategorySelected(.science))
        try await waitForStateUpdate()

        #expect(sut.viewState.errorMessage == "The Internet connection appears to be offline.")
        #expect(sut.viewState.articles.isEmpty)
    }
}
