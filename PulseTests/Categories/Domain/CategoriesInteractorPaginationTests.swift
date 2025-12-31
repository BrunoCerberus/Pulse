import Combine
import Foundation
@testable import Pulse
import Testing

@Suite("CategoriesDomainInteractor Pagination Tests")
@MainActor
struct CategoriesInteractorPaginationTests {
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

    // MARK: - Load More Tests

    @Test("Load more appends articles")
    func loadMoreAppendsArticles() async throws {
        mockCategoriesService.articlesResult = .success(makeMockArticles(count: 20))

        sut.dispatch(action: .selectCategory(.technology))
        try await Task.sleep(nanoseconds: 500_000_000)

        let initialCount = sut.currentState.articles.count

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
        mockCategoriesService.articlesResult = .success([newArticle])

        sut.dispatch(action: .loadMore)
        try await Task.sleep(nanoseconds: 500_000_000)

        let state = sut.currentState
        #expect(state.articles.count > initialCount)
        #expect(state.currentPage == 2)
    }

    @Test("Load more deduplicates articles")
    func loadMoreDeduplicatesArticles() async throws {
        mockCategoriesService.articlesResult = .success(Article.mockArticles)

        sut.dispatch(action: .selectCategory(.technology))
        try await Task.sleep(nanoseconds: 500_000_000)

        let initialCount = sut.currentState.articles.count

        // Return same articles - should be deduplicated
        sut.dispatch(action: .loadMore)
        try await Task.sleep(nanoseconds: 500_000_000)

        // Count should not increase due to deduplication
        #expect(sut.currentState.articles.count == initialCount)
    }

    @Test("Load more requires selected category")
    func loadMoreRequiresSelectedCategory() async throws {
        // No category selected
        sut.dispatch(action: .loadMore)

        try await Task.sleep(nanoseconds: 300_000_000)

        // Should do nothing - page should still be 1
        #expect(sut.currentState.currentPage == 1)
        #expect(!sut.currentState.isLoadingMore)
    }

    @Test("Load more sets loading more state")
    func loadMoreSetsLoadingMoreState() async throws {
        mockCategoriesService.articlesResult = .success(makeMockArticles(count: 20))

        sut.dispatch(action: .selectCategory(.technology))
        try await Task.sleep(nanoseconds: 500_000_000)

        var cancellables = Set<AnyCancellable>()
        var loadingMoreStates: [Bool] = []

        sut.statePublisher
            .map(\.isLoadingMore)
            .sink { isLoadingMore in
                loadingMoreStates.append(isLoadingMore)
            }
            .store(in: &cancellables)

        sut.dispatch(action: .loadMore)
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(loadingMoreStates.contains(true))
        #expect(loadingMoreStates.last == false)
    }

    @Test("Load more respects hasMorePages")
    func loadMoreRespectsHasMorePages() async throws {
        // Return fewer than 20 articles to indicate no more pages
        mockCategoriesService.articlesResult = .success(Array(Article.mockArticles.prefix(5)))

        sut.dispatch(action: .selectCategory(.technology))
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(!sut.currentState.hasMorePages)

        // Try to load more - should do nothing
        sut.dispatch(action: .loadMore)
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.currentState.currentPage == 1)
    }

    // MARK: - Refresh Tests

    @Test("Refresh reloads category")
    func refreshReloadsCategory() async throws {
        mockCategoriesService.articlesResult = .success(Article.mockArticles)

        sut.dispatch(action: .selectCategory(.technology))
        try await Task.sleep(nanoseconds: 500_000_000)

        sut.dispatch(action: .refresh)
        try await Task.sleep(nanoseconds: 500_000_000)

        let state = sut.currentState
        #expect(!state.isRefreshing)
        #expect(!state.articles.isEmpty)
        #expect(state.selectedCategory == .technology)
    }

    @Test("Refresh requires selected category")
    func refreshRequiresSelectedCategory() async throws {
        // No category selected
        sut.dispatch(action: .refresh)

        try await Task.sleep(nanoseconds: 300_000_000)

        // Should do nothing
        #expect(!sut.currentState.isRefreshing)
        #expect(sut.currentState.articles.isEmpty)
    }

    @Test("Refresh clears existing articles")
    func refreshClearsExistingArticles() async throws {
        mockCategoriesService.articlesResult = .success(Article.mockArticles)

        sut.dispatch(action: .selectCategory(.technology))
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(!sut.currentState.articles.isEmpty)

        var cancellables = Set<AnyCancellable>()
        var articleCounts: [Int] = []

        sut.statePublisher
            .map(\.articles.count)
            .sink { count in
                articleCounts.append(count)
            }
            .store(in: &cancellables)

        sut.dispatch(action: .refresh)
        try await Task.sleep(nanoseconds: 500_000_000)

        // Should have cleared to 0 at some point
        #expect(articleCounts.contains(0))
    }

    @Test("Refresh resets page to 1")
    func refreshResetsPage() async throws {
        mockCategoriesService.articlesResult = .success(makeMockArticles(count: 20))

        sut.dispatch(action: .selectCategory(.technology))
        try await Task.sleep(nanoseconds: 500_000_000)

        sut.dispatch(action: .loadMore)
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(sut.currentState.currentPage == 2)

        sut.dispatch(action: .refresh)
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(sut.currentState.currentPage == 1)
    }

    @Test("Refresh handles error")
    func refreshHandlesError() async throws {
        mockCategoriesService.articlesResult = .success(Article.mockArticles)

        sut.dispatch(action: .selectCategory(.technology))
        try await Task.sleep(nanoseconds: 500_000_000)

        let testError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Refresh error"])
        mockCategoriesService.articlesResult = .failure(testError)

        sut.dispatch(action: .refresh)
        try await Task.sleep(nanoseconds: 500_000_000)

        let state = sut.currentState
        #expect(!state.isRefreshing)
        #expect(state.error == "Refresh error")
    }
}
