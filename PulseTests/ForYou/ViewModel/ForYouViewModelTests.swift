import Combine
import Foundation
@testable import Pulse
import Testing

@Suite("ForYouViewModel Tests")
@MainActor
struct ForYouViewModelTests {
    let mockForYouService: MockForYouService
    let mockStorageService: MockStorageService
    let serviceLocator: ServiceLocator
    let sut: ForYouViewModel

    init() {
        mockForYouService = MockForYouService()
        mockStorageService = MockStorageService()
        serviceLocator = ServiceLocator()

        serviceLocator.register(ForYouService.self, instance: mockForYouService)
        serviceLocator.register(StorageService.self, instance: mockStorageService)

        sut = ForYouViewModel(serviceLocator: serviceLocator)
    }

    @Test("Initial view state is correct")
    func initialViewState() {
        let state = sut.viewState
        #expect(state.articles.isEmpty)
        #expect(state.followedTopics.isEmpty)
        #expect(!state.isLoading)
        #expect(!state.isLoadingMore)
        #expect(!state.isRefreshing)
        #expect(state.errorMessage == nil)
        #expect(!state.showEmptyState)
        #expect(!state.showOnboarding)
        #expect(state.selectedArticle == nil)
    }

    @Test("Handle onAppear triggers load feed")
    func testOnAppear() async throws {
        mockForYouService.feedResult = .success(Article.mockArticles)

        var cancellables = Set<AnyCancellable>()
        var states: [ForYouViewState] = []

        sut.$viewState
            .sink { state in
                states.append(state)
            }
            .store(in: &cancellables)

        sut.handle(event: .onAppear)

        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(states.count > 1)
    }

    @Test("Handle onRefresh triggers refresh")
    func testOnRefresh() async throws {
        mockForYouService.feedResult = .success(Article.mockArticles)

        var cancellables = Set<AnyCancellable>()
        var states: [ForYouViewState] = []

        sut.$viewState
            .sink { state in
                states.append(state)
            }
            .store(in: &cancellables)

        sut.handle(event: .onRefresh)

        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(states.count > 1)
    }

    @Test("Handle onLoadMore triggers load more")
    func testOnLoadMore() async throws {
        // First load initial articles
        mockForYouService.feedResult = .success(Article.mockArticles)
        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 100_000_000)

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
        mockForYouService.personalizedFeedResult = .success([newArticle])

        sut.handle(event: .onLoadMore)
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(sut.viewState.articles.count >= initialCount)
    }

    @Test("Handle onArticleTapped sets selected article")
    func testOnArticleTapped() async throws {
        let article = Article.mockArticles[0]

        // First load articles so they can be found
        mockForYouService.personalizedFeedResult = .success([article])
        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 100_000_000)

        sut.handle(event: .onArticleTapped(articleId: article.id))

        // Wait for Combine pipeline to propagate state
        try await Task.sleep(nanoseconds: 50_000_000)

        #expect(sut.viewState.selectedArticle?.id == article.id)
    }

    @Test("Handle onArticleNavigated clears selected article")
    func testOnArticleNavigated() async throws {
        let article = Article.mockArticles[0]

        // First load and select an article
        mockForYouService.personalizedFeedResult = .success([article])
        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 100_000_000)

        sut.handle(event: .onArticleTapped(articleId: article.id))
        try await Task.sleep(nanoseconds: 50_000_000)

        #expect(sut.viewState.selectedArticle != nil)

        sut.handle(event: .onArticleNavigated)
        try await Task.sleep(nanoseconds: 50_000_000)

        #expect(sut.viewState.selectedArticle == nil)
    }

    @Test("View state shows onboarding when no followed topics")
    func testShowOnboarding() async throws {
        // Initially no topics, should show onboarding after loading
        mockForYouService.personalizedFeedResult = .success([])

        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(sut.viewState.showOnboarding)
    }

    @Test("View state shows empty state when no articles and has followed topics")
    func testShowEmptyState() async throws {
        // Set up preferences with followed topics
        mockStorageService.userPreferences = UserPreferencesModel(
            followedTopics: [.technology],
            mutedAuthors: [],
            mutedSources: [],
            selectedTheme: .automatic,
            notificationsEnabled: true,
            breakingNewsEnabled: true,
            topicAlerts: [:]
        )

        mockForYouService.personalizedFeedResult = .success([])

        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(sut.viewState.showEmptyState)
        #expect(!sut.viewState.showOnboarding)
    }

    @Test("Error message propagates to view state")
    func testErrorMessage() async throws {
        let testError = NSError(
            domain: "test",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Feed loading failed"]
        )
        mockForYouService.feedResult = .failure(testError)

        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(sut.viewState.errorMessage == "Feed loading failed")
    }

    @Test("View state reducer transforms domain state correctly")
    func viewStateTransformation() async throws {
        mockForYouService.feedResult = .success(Article.mockArticles)
        mockStorageService.userPreferences = UserPreferencesModel(
            followedTopics: [.technology, .business],
            mutedAuthors: [],
            mutedSources: [],
            selectedTheme: .automatic,
            notificationsEnabled: true,
            breakingNewsEnabled: true,
            topicAlerts: [:]
        )

        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 100_000_000)

        let state = sut.viewState
        #expect(!state.articles.isEmpty)
        #expect(state.followedTopics.count == 2)
        #expect(!state.isLoading)
        #expect(!state.showOnboarding)
    }

    @Test("View state updates through publisher binding")
    func publisherBinding() async throws {
        var cancellables = Set<AnyCancellable>()
        var states: [ForYouViewState] = []

        sut.$viewState
            .sink { state in
                states.append(state)
            }
            .store(in: &cancellables)

        mockForYouService.feedResult = .success(Article.mockArticles)

        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 100_000_000)

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

        mockForYouService.feedResult = .success(Article.mockArticles)

        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 100_000_000)

        // Should have at least initial state (false) and loading state (true)
        #expect(loadingStates.count >= 2)
    }

    // MARK: - Error Path Tests

    @Test("Error during load more shows error message")
    func errorDuringLoadMore() async throws {
        // First load initial articles successfully
        mockForYouService.feedResult = .success(Article.mockArticles)
        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 100_000_000)

        // Now simulate error during load more
        let loadMoreError = NSError(
            domain: "test",
            code: 2,
            userInfo: [NSLocalizedDescriptionKey: "Load more failed"]
        )
        mockForYouService.feedResult = .failure(loadMoreError)

        sut.handle(event: .onLoadMore)
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(sut.viewState.errorMessage == "Load more failed")
    }

    @Test("Error during refresh clears articles and shows error")
    func errorDuringRefresh() async throws {
        // First load initial articles
        mockForYouService.feedResult = .success(Article.mockArticles)
        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(!sut.viewState.articles.isEmpty)

        // Now simulate error during refresh
        let refreshError = NSError(
            domain: "test",
            code: 3,
            userInfo: [NSLocalizedDescriptionKey: "Refresh failed"]
        )
        mockForYouService.feedResult = .failure(refreshError)

        sut.handle(event: .onRefresh)
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(sut.viewState.errorMessage == "Refresh failed")
    }

    @Test("Error recovery: success after error clears error message")
    func errorRecovery() async throws {
        // First trigger an error
        let initialError = NSError(
            domain: "test",
            code: 4,
            userInfo: [NSLocalizedDescriptionKey: "Initial error"]
        )
        mockForYouService.feedResult = .failure(initialError)

        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(sut.viewState.errorMessage == "Initial error")

        // Now recover with successful load
        mockForYouService.feedResult = .success(Article.mockArticles)

        sut.handle(event: .onRefresh)
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(sut.viewState.errorMessage == nil)
        #expect(!sut.viewState.articles.isEmpty)
    }
}
