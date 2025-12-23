import Combine
import Foundation
@testable import Pulse
import Testing

@Suite("ForYouDomainInteractor Tests")
@MainActor
struct ForYouDomainInteractorTests {
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
        #expect(state.articles.isEmpty)
        #expect(state.preferences == .default)
        #expect(!state.isLoading)
        #expect(!state.isLoadingMore)
        #expect(!state.isRefreshing)
        #expect(state.error == nil)
        #expect(state.currentPage == 1)
        #expect(state.hasMorePages)
        #expect(!state.hasLoadedInitialData)
    }

    // MARK: - Load Feed Tests

    @Test("Load feed fetches articles")
    func loadFeedFetchesArticles() async throws {
        mockForYouService.feedResult = .success(Article.mockArticles)

        sut.dispatch(action: .loadFeed)

        try await Task.sleep(nanoseconds: 500_000_000)

        let state = sut.currentState
        #expect(!state.isLoading)
        #expect(!state.articles.isEmpty)
        #expect(state.hasLoadedInitialData)
        #expect(state.error == nil)
    }

    @Test("Load feed uses stored preferences")
    func loadFeedUsesStoredPreferences() async throws {
        let customPreferences = UserPreferences(
            followedTopics: [.technology, .science],
            followedSources: [],
            mutedSources: [],
            mutedKeywords: [],
            preferredLanguage: "en",
            notificationsEnabled: true,
            breakingNewsNotifications: true
        )
        mockStorageService.userPreferences = customPreferences
        mockForYouService.feedResult = .success(Article.mockArticles)

        sut.dispatch(action: .loadFeed)

        try await Task.sleep(nanoseconds: 500_000_000)

        let state = sut.currentState
        #expect(state.preferences == customPreferences)
    }

    @Test("Load feed skips if already loaded with same preferences")
    func loadFeedSkipsIfAlreadyLoaded() async throws {
        mockForYouService.feedResult = .success(Article.mockArticles)

        // First load
        sut.dispatch(action: .loadFeed)
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(sut.currentState.hasLoadedInitialData)
        let firstLoadArticles = sut.currentState.articles

        // Second load - should skip
        sut.dispatch(action: .loadFeed)
        try await Task.sleep(nanoseconds: 300_000_000)

        // Articles should be the same (not reloaded)
        #expect(sut.currentState.articles == firstLoadArticles)
    }

    @Test("Load feed reloads when preferences change")
    func loadFeedReloadsWhenPreferencesChange() async throws {
        mockForYouService.feedResult = .success(Article.mockArticles)

        // First load with default preferences
        sut.dispatch(action: .loadFeed)
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(sut.currentState.hasLoadedInitialData)

        // Change preferences
        let newPreferences = UserPreferences(
            followedTopics: [.sports],
            followedSources: [],
            mutedSources: [],
            mutedKeywords: [],
            preferredLanguage: "en",
            notificationsEnabled: true,
            breakingNewsNotifications: true
        )
        mockStorageService.userPreferences = newPreferences

        // New articles for reload
        let newArticles = [Article.mockArticles[0]]
        mockForYouService.feedResult = .success(newArticles)

        // Second load - should reload because preferences changed
        sut.dispatch(action: .loadFeed)
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(sut.currentState.preferences == newPreferences)
        #expect(sut.currentState.articles.count == 1)
    }

    @Test("Load feed sets loading state")
    func loadFeedSetsLoadingState() async throws {
        var cancellables = Set<AnyCancellable>()
        var loadingStates: [Bool] = []

        sut.statePublisher
            .map(\.isLoading)
            .sink { isLoading in
                loadingStates.append(isLoading)
            }
            .store(in: &cancellables)

        mockForYouService.feedResult = .success(Article.mockArticles)

        sut.dispatch(action: .loadFeed)

        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(loadingStates.contains(true))
        #expect(loadingStates.last == false)
    }

    @Test("Load feed handles error")
    func loadFeedHandlesError() async throws {
        let testError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Feed error"])
        mockForYouService.feedResult = .failure(testError)

        sut.dispatch(action: .loadFeed)

        try await Task.sleep(nanoseconds: 500_000_000)

        let state = sut.currentState
        #expect(!state.isLoading)
        #expect(state.error != nil)
        #expect(state.error == "Feed error")
    }

    @Test("Load feed clears articles when preferences change")
    func loadFeedClearsArticlesOnPreferenceChange() async throws {
        mockForYouService.feedResult = .success(Article.mockArticles)

        // First load
        sut.dispatch(action: .loadFeed)
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(!sut.currentState.articles.isEmpty)

        // Change preferences
        mockStorageService.userPreferences = UserPreferences(
            followedTopics: [.business],
            followedSources: [],
            mutedSources: [],
            mutedKeywords: [],
            preferredLanguage: "en",
            notificationsEnabled: true,
            breakingNewsNotifications: true
        )

        // Track states
        var cancellables = Set<AnyCancellable>()
        var articleCounts: [Int] = []

        sut.statePublisher
            .map(\.articles.count)
            .sink { count in
                articleCounts.append(count)
            }
            .store(in: &cancellables)

        sut.dispatch(action: .loadFeed)
        try await Task.sleep(nanoseconds: 500_000_000)

        // Should have cleared to 0 at some point
        #expect(articleCounts.contains(0))
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

    // MARK: - Select Article Tests

    @Test("Select article saves to reading history")
    func selectArticleSavesToHistory() async throws {
        let article = Article.mockArticles[0]

        sut.dispatch(action: .selectArticle(article))

        try await Task.sleep(nanoseconds: 200_000_000)

        let history = try await mockStorageService.fetchReadingHistory()
        #expect(history.contains(where: { $0.id == article.id }))
    }

    // MARK: - Empty Feed Tests

    @Test("Empty feed with no followed topics")
    func emptyFeedWithNoFollowedTopics() async throws {
        mockStorageService.userPreferences = .default // No followed topics
        mockForYouService.feedResult = .success([])

        sut.dispatch(action: .loadFeed)
        try await Task.sleep(nanoseconds: 500_000_000)

        let state = sut.currentState
        #expect(state.articles.isEmpty)
        #expect(state.hasLoadedInitialData)
        #expect(state.error == nil)
    }
}
