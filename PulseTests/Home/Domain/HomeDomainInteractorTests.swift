import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("HomeDomainInteractor Tests")
@MainActor
struct HomeDomainInteractorTests {
    let mockNewsService: MockNewsService
    let mockStorageService: MockStorageService
    let serviceLocator: ServiceLocator
    let sut: HomeDomainInteractor

    init() {
        mockNewsService = MockNewsService()
        mockStorageService = MockStorageService()
        serviceLocator = ServiceLocator()

        serviceLocator.register(NewsService.self, instance: mockNewsService)
        serviceLocator.register(StorageService.self, instance: mockStorageService)
        serviceLocator.register(SettingsService.self, instance: MockSettingsService())

        sut = HomeDomainInteractor(serviceLocator: serviceLocator)
    }

    @Test("Initial state is correct")
    func initialState() {
        let state = sut.currentState
        #expect(state.breakingNews.isEmpty)
        #expect(state.headlines.isEmpty)
        #expect(!state.isLoading)
        #expect(!state.isLoadingMore)
        #expect(state.error == nil)
        #expect(state.currentPage == 1)
        #expect(state.hasMorePages)
    }

    @Test("Load initial data updates state correctly")
    func testLoadInitialData() async throws {
        mockNewsService.topHeadlinesResult = .success(Article.mockArticles)
        mockNewsService.breakingNewsResult = .success(Array(Article.mockArticles.prefix(2)))

        var cancellables = Set<AnyCancellable>()
        var states: [HomeDomainState] = []

        sut.statePublisher
            .sink { state in
                states.append(state)
            }
            .store(in: &cancellables)

        sut.dispatch(action: .loadInitialData)

        try await Task.sleep(nanoseconds: 500_000_000)

        let finalState = sut.currentState
        #expect(!finalState.isLoading)
        #expect(finalState.error == nil)
    }

    @Test("Error handling works correctly")
    func errorHandling() async throws {
        let testError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        mockNewsService.topHeadlinesResult = .failure(testError)

        sut.dispatch(action: .loadInitialData)

        try await Task.sleep(nanoseconds: 500_000_000)

        let finalState = sut.currentState
        #expect(!finalState.isLoading)
        #expect(finalState.error != nil)
    }

    @Test("Refresh resets page and reloads data")
    func testRefresh() async throws {
        mockNewsService.topHeadlinesResult = .success(Article.mockArticles)
        mockNewsService.breakingNewsResult = .success(Array(Article.mockArticles.prefix(2)))

        sut.dispatch(action: .refresh)

        try await Task.sleep(nanoseconds: 500_000_000)

        let state = sut.currentState
        #expect(state.currentPage == 1)
        #expect(!state.isLoading)
        #expect(!state.breakingNews.isEmpty)
    }

    @Test("Select article saves to reading history")
    func testSelectArticle() async throws {
        let article = Article.mockArticles[0]

        // First load articles so they can be found
        mockNewsService.topHeadlinesResult = .success([article])
        mockNewsService.breakingNewsResult = .success([])
        sut.dispatch(action: .loadInitialData)
        try await Task.sleep(nanoseconds: 500_000_000)

        sut.dispatch(action: .selectArticle(articleId: article.id))

        // Allow enough time for background Task to complete
        try await Task.sleep(nanoseconds: 300_000_000)

        let history = try await mockStorageService.fetchReadingHistory()
        #expect(history.contains(where: { $0.id == article.id }))
    }

    @Test("Bookmark article toggles bookmark status")
    func testBookmarkArticle() async throws {
        let article = Article.mockArticles[0]

        // First load articles so they can be found
        mockNewsService.topHeadlinesResult = .success([article])
        mockNewsService.breakingNewsResult = .success([])
        sut.dispatch(action: .loadInitialData)
        try await Task.sleep(nanoseconds: 500_000_000)

        sut.dispatch(action: .bookmarkArticle(articleId: article.id))

        // Allow enough time for background Task to complete
        try await Task.sleep(nanoseconds: 300_000_000)

        let isBookmarked = await mockStorageService.isBookmarked(article.id)
        #expect(isBookmarked)
    }

    // MARK: - Category Selection Tests

    @Test("Select category updates selected category and clears content")
    func testSelectCategory() async throws {
        // First load initial data
        mockNewsService.topHeadlinesResult = .success(Article.mockArticles)
        mockNewsService.breakingNewsResult = .success(Array(Article.mockArticles.prefix(2)))
        sut.dispatch(action: .loadInitialData)
        try await Task.sleep(nanoseconds: 500_000_000)

        // Verify initial state has content
        #expect(!sut.currentState.headlines.isEmpty)
        #expect(sut.currentState.selectedCategory == nil)

        // Select a category
        sut.dispatch(action: .selectCategory(.technology))
        try await Task.sleep(nanoseconds: 500_000_000)

        let state = sut.currentState
        #expect(state.selectedCategory == .technology)
        #expect(state.breakingNews.isEmpty) // Breaking news cleared for category filter
    }

    @Test("Select same category does nothing")
    func selectSameCategoryNoOp() async throws {
        // Set up with a category already selected
        sut.dispatch(action: .selectCategory(.business))
        try await Task.sleep(nanoseconds: 500_000_000)

        let stateBeforeReselect = sut.currentState

        // Select the same category again
        sut.dispatch(action: .selectCategory(.business))
        try await Task.sleep(nanoseconds: 100_000_000)

        // State should remain unchanged (no re-fetch triggered)
        #expect(sut.currentState.selectedCategory == stateBeforeReselect.selectedCategory)
    }

    @Test("Select nil category returns to All tab")
    func selectNilCategoryReturnsToAll() async throws {
        // First select a category
        sut.dispatch(action: .selectCategory(.technology))
        try await Task.sleep(nanoseconds: 500_000_000)
        #expect(sut.currentState.selectedCategory == .technology)

        // Set up mock for All tab (includes breaking news)
        mockNewsService.topHeadlinesResult = .success(Article.mockArticles)
        mockNewsService.breakingNewsResult = .success(Array(Article.mockArticles.prefix(2)))

        // Select nil to return to All
        sut.dispatch(action: .selectCategory(nil))
        try await Task.sleep(nanoseconds: 500_000_000)

        let state = sut.currentState
        #expect(state.selectedCategory == nil)
        #expect(!state.breakingNews.isEmpty) // Breaking news should be fetched for All tab
    }

    @Test("Category selection fetches category-filtered headlines")
    func categorySelectionFetchesCategoryHeadlines() async throws {
        let technologyArticles = Article.mockArticles.filter { $0.category == .technology }
        mockNewsService.categoryHeadlinesResult = .success(technologyArticles)

        sut.dispatch(action: .selectCategory(.technology))
        try await Task.sleep(nanoseconds: 500_000_000)

        let state = sut.currentState
        #expect(state.selectedCategory == .technology)
        #expect(!state.isLoading)
        #expect(state.hasLoadedInitialData)
    }

    @Test("Load more respects selected category")
    func loadMoreWithCategory() async throws {
        // First select a category and load initial data
        mockNewsService.categoryHeadlinesResult = .success(Article.mockArticles)
        sut.dispatch(action: .selectCategory(.technology))
        try await Task.sleep(nanoseconds: 500_000_000)

        // Load more
        sut.dispatch(action: .loadMoreHeadlines)
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(sut.currentState.selectedCategory == .technology)
        #expect(sut.currentState.currentPage >= 1)
    }

    @Test("Refresh respects selected category")
    func refreshWithCategory() async throws {
        // First select a category
        mockNewsService.categoryHeadlinesResult = .success(Article.mockArticles)
        sut.dispatch(action: .selectCategory(.technology))
        try await Task.sleep(nanoseconds: 500_000_000)

        // Refresh
        sut.dispatch(action: .refresh)
        try await Task.sleep(nanoseconds: 500_000_000)

        let state = sut.currentState
        #expect(state.selectedCategory == .technology)
        #expect(state.breakingNews.isEmpty) // No breaking news for category filter
    }

}

// MARK: - Media Filtering Tests

extension HomeDomainInteractorTests {
    @Test("Media items are filtered from headlines")
    func mediaItemsFilteredFromHeadlines() async throws {
        let videoArticle = Article(
            id: "video-1",
            title: "Test Video",
            source: ArticleSource(id: "test", name: "Test"),
            url: "https://example.com",
            publishedAt: Date(),
            mediaType: .video
        )
        let regularArticle = Article(
            id: "article-1",
            title: "Test Article",
            source: ArticleSource(id: "test", name: "Test"),
            url: "https://example.com",
            publishedAt: Date()
        )

        mockNewsService.topHeadlinesResult = .success([videoArticle, regularArticle])
        mockNewsService.breakingNewsResult = .success([])

        sut.dispatch(action: .loadInitialData)
        try await Task.sleep(nanoseconds: 500_000_000)

        let state = sut.currentState
        #expect(state.headlines.count == 1)
        #expect(state.headlines.first?.id == regularArticle.id)
        #expect(!state.headlines.contains(where: { $0.isMedia }))
    }

    @Test("Media items are filtered from breaking news")
    func mediaItemsFilteredFromBreakingNews() async throws {
        let podcastArticle = Article(
            id: "podcast-1",
            title: "Test Podcast",
            source: ArticleSource(id: "test", name: "Test"),
            url: "https://example.com",
            publishedAt: Date(),
            mediaType: .podcast
        )
        let regularArticle = Article(
            id: "article-1",
            title: "Test Article",
            source: ArticleSource(id: "test", name: "Test"),
            url: "https://example.com",
            publishedAt: Date()
        )

        mockNewsService.breakingNewsResult = .success([podcastArticle, regularArticle])
        mockNewsService.topHeadlinesResult = .success([])

        sut.dispatch(action: .loadInitialData)
        try await Task.sleep(nanoseconds: 500_000_000)

        let state = sut.currentState
        #expect(state.breakingNews.count == 1)
        #expect(state.breakingNews.first?.id == regularArticle.id)
        #expect(!state.breakingNews.contains(where: { $0.isMedia }))
    }

    @Test("Media items are filtered during pagination")
    func mediaItemsFilteredDuringPagination() async throws {
        // Load initial page with 20 articles to ensure hasMorePages is true
        var initialArticles: [Article] = []
        for index in 0 ..< 20 {
            initialArticles.append(Article(
                id: "article-\(index)",
                title: "Initial Article \(index)",
                source: ArticleSource(id: "test", name: "Test"),
                url: "https://example.com",
                publishedAt: Date()
            ))
        }
        mockNewsService.topHeadlinesResult = .success(initialArticles)
        mockNewsService.breakingNewsResult = .success([])
        sut.dispatch(action: .loadInitialData)
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(sut.currentState.hasMorePages) // Verify pagination is enabled

        // Second page has media items mixed with articles
        let videoArticle = Article(
            id: "video-1",
            title: "Test Video",
            source: ArticleSource(id: "test", name: "Test"),
            url: "https://example.com",
            publishedAt: Date(),
            mediaType: .video
        )
        let newArticle = Article(
            id: "article-new",
            title: "New Article",
            source: ArticleSource(id: "test", name: "Test"),
            url: "https://example.com",
            publishedAt: Date()
        )
        mockNewsService.topHeadlinesResult = .success([videoArticle, newArticle])

        sut.dispatch(action: .loadMoreHeadlines)
        try await Task.sleep(nanoseconds: 500_000_000)

        let state = sut.currentState
        #expect(!state.headlines.contains(where: { $0.isMedia }))
        #expect(state.headlines.count == 21) // 20 initial + 1 new (video filtered)
    }

    @Test("Media items are filtered from category headlines")
    func mediaItemsFilteredFromCategoryHeadlines() async throws {
        let videoArticle = Article(
            id: "video-1",
            title: "Tech Video",
            source: ArticleSource(id: "test", name: "Test"),
            url: "https://example.com",
            publishedAt: Date(),
            category: .technology,
            mediaType: .video
        )
        let regularArticle = Article(
            id: "article-1",
            title: "Tech Article",
            source: ArticleSource(id: "test", name: "Test"),
            url: "https://example.com",
            publishedAt: Date(),
            category: .technology
        )

        mockNewsService.categoryHeadlinesResult = .success([videoArticle, regularArticle])

        sut.dispatch(action: .selectCategory(.technology))
        try await Task.sleep(nanoseconds: 500_000_000)

        let state = sut.currentState
        #expect(state.headlines.count == 1)
        #expect(state.headlines.first?.id == regularArticle.id)
        #expect(!state.headlines.contains(where: { $0.isMedia }))
    }
}
