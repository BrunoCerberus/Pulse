import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("ForYouDomainInteractor Pagination Tests")
@MainActor
struct ForYouDomainInteractorPaginationTests {
    let mockForYouService: MockForYouService
    let mockStorageService: MockStorageService
    let serviceLocator: ServiceLocator
    let sut: ForYouDomainInteractor

    init() {
        mockForYouService = MockForYouService()
        mockStorageService = MockStorageService()
        serviceLocator = ServiceLocator()

        serviceLocator.register(ForYouService.self, instance: mockForYouService)
        serviceLocator.register(StorageService.self, instance: mockStorageService)

        sut = ForYouDomainInteractor(serviceLocator: serviceLocator)
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
        mockForYouService.feedResult = .success(makeMockArticles(count: 20))

        sut.dispatch(action: .loadFeed)
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
        mockForYouService.feedResult = .success([newArticle])

        sut.dispatch(action: .loadMore)
        try await Task.sleep(nanoseconds: 500_000_000)

        let state = sut.currentState
        #expect(state.articles.count > initialCount)
        #expect(state.currentPage == 2)
    }

    @Test("Load more deduplicates articles")
    func loadMoreDeduplicatesArticles() async throws {
        mockForYouService.feedResult = .success(Article.mockArticles)

        sut.dispatch(action: .loadFeed)
        try await Task.sleep(nanoseconds: 500_000_000)

        let initialCount = sut.currentState.articles.count

        // Return same articles - should be deduplicated
        sut.dispatch(action: .loadMore)
        try await Task.sleep(nanoseconds: 500_000_000)

        // Count should not increase due to deduplication
        #expect(sut.currentState.articles.count == initialCount)
    }

    @Test("Load more sets loading more state")
    func loadMoreSetsLoadingMoreState() async throws {
        mockForYouService.feedResult = .success(makeMockArticles(count: 20))

        sut.dispatch(action: .loadFeed)
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
        mockForYouService.feedResult = .success(Array(Article.mockArticles.prefix(5)))

        sut.dispatch(action: .loadFeed)
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(!sut.currentState.hasMorePages)

        // Try to load more - should do nothing
        sut.dispatch(action: .loadMore)
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.currentState.currentPage == 1)
    }

    // MARK: - Refresh Tests

    @Test("Refresh reloads feed")
    func refreshReloadsFeed() async throws {
        mockForYouService.feedResult = .success(Article.mockArticles)

        sut.dispatch(action: .refresh)
        try await Task.sleep(nanoseconds: 500_000_000)

        let state = sut.currentState
        #expect(!state.isRefreshing)
        #expect(!state.articles.isEmpty)
        #expect(state.hasLoadedInitialData)
    }

    @Test("Refresh clears existing articles")
    func refreshClearsExistingArticles() async throws {
        mockForYouService.feedResult = .success(Article.mockArticles)

        sut.dispatch(action: .loadFeed)
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
        mockForYouService.feedResult = .success(makeMockArticles(count: 20))

        sut.dispatch(action: .loadFeed)
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
        let testError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Refresh error"])
        mockForYouService.feedResult = .failure(testError)

        sut.dispatch(action: .refresh)
        try await Task.sleep(nanoseconds: 500_000_000)

        let state = sut.currentState
        #expect(!state.isRefreshing)
        #expect(state.error == "Refresh error")
    }
}
