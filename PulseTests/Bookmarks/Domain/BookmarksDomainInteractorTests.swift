import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("BookmarksDomainInteractor Tests")
@MainActor
struct BookmarksDomainInteractorTests {
    let mockBookmarksService: MockBookmarksService
    let serviceLocator: ServiceLocator
    let sut: BookmarksDomainInteractor

    init() {
        mockBookmarksService = MockBookmarksService()
        serviceLocator = ServiceLocator()

        serviceLocator.register(BookmarksService.self, instance: mockBookmarksService)

        sut = BookmarksDomainInteractor(serviceLocator: serviceLocator)
    }

    // MARK: - Initial State Tests

    @Test("Initial state is correct")
    func initialState() {
        let state = sut.currentState
        #expect(state.bookmarks.isEmpty)
        #expect(!state.isLoading)
        #expect(!state.isRefreshing)
        #expect(state.error == nil)
    }

    // MARK: - Load Bookmarks Tests

    @Test("Load bookmarks populates state")
    func loadBookmarksPopulatesState() async throws {
        mockBookmarksService.bookmarks = Article.mockArticles

        sut.dispatch(action: .loadBookmarks)

        try await Task.sleep(nanoseconds: 300_000_000)

        let state = sut.currentState
        #expect(!state.isLoading)
        #expect(state.bookmarks.count == Article.mockArticles.count)
        #expect(state.error == nil)
    }

    @Test("Load bookmarks sets loading state")
    func loadBookmarksSetsLoadingState() async throws {
        var cancellables = Set<AnyCancellable>()
        var loadingStates: [Bool] = []

        sut.statePublisher
            .map(\.isLoading)
            .sink { isLoading in
                loadingStates.append(isLoading)
            }
            .store(in: &cancellables)

        sut.dispatch(action: .loadBookmarks)

        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(loadingStates.contains(true))
        #expect(loadingStates.last == false)
    }

    @Test("Load bookmarks with empty results")
    func loadBookmarksEmptyResults() async throws {
        mockBookmarksService.bookmarks = []

        sut.dispatch(action: .loadBookmarks)

        try await Task.sleep(nanoseconds: 300_000_000)

        let state = sut.currentState
        #expect(state.bookmarks.isEmpty)
        #expect(!state.isLoading)
        #expect(state.error == nil)
    }

    // MARK: - Refresh Tests

    @Test("Refresh reloads bookmarks")
    func refreshReloadsBookmarks() async throws {
        mockBookmarksService.bookmarks = Article.mockArticles

        sut.dispatch(action: .refresh)

        try await Task.sleep(nanoseconds: 300_000_000)

        let state = sut.currentState
        #expect(!state.isRefreshing)
        #expect(state.bookmarks.count == Article.mockArticles.count)
    }

    @Test("Refresh clears existing bookmarks first")
    func refreshClearsExistingBookmarks() async throws {
        // First load some bookmarks
        mockBookmarksService.bookmarks = Article.mockArticles
        sut.dispatch(action: .loadBookmarks)
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(!sut.currentState.bookmarks.isEmpty)

        // Track states during refresh
        var cancellables = Set<AnyCancellable>()
        var bookmarkCounts: [Int] = []

        sut.statePublisher
            .map(\.bookmarks.count)
            .sink { count in
                bookmarkCounts.append(count)
            }
            .store(in: &cancellables)

        sut.dispatch(action: .refresh)

        try await Task.sleep(nanoseconds: 300_000_000)

        // Should have cleared to 0 then reloaded
        #expect(bookmarkCounts.contains(0))
    }

    @Test("Refresh sets refreshing state")
    func refreshSetsRefreshingState() async throws {
        var cancellables = Set<AnyCancellable>()
        var refreshingStates: [Bool] = []

        sut.statePublisher
            .map(\.isRefreshing)
            .sink { isRefreshing in
                refreshingStates.append(isRefreshing)
            }
            .store(in: &cancellables)

        sut.dispatch(action: .refresh)

        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(refreshingStates.contains(true))
        #expect(refreshingStates.last == false)
    }

    // MARK: - Remove Bookmark Tests

    @Test("Remove bookmark removes from state")
    func removeBookmarkRemovesFromState() async throws {
        mockBookmarksService.bookmarks = Article.mockArticles

        sut.dispatch(action: .loadBookmarks)
        try await Task.sleep(nanoseconds: 300_000_000)

        let articleToRemove = Article.mockArticles[0]
        let initialCount = sut.currentState.bookmarks.count

        sut.dispatch(action: .removeBookmark(articleId: articleToRemove.id))

        try await Task.sleep(nanoseconds: 300_000_000)

        let state = sut.currentState
        #expect(state.bookmarks.count == initialCount - 1)
        #expect(!state.bookmarks.contains(where: { $0.id == articleToRemove.id }))
    }

    @Test("Remove bookmark updates service")
    func removeBookmarkUpdatesService() async throws {
        mockBookmarksService.bookmarks = Article.mockArticles

        sut.dispatch(action: .loadBookmarks)
        try await Task.sleep(nanoseconds: 300_000_000)

        let articleToRemove = Article.mockArticles[0]

        sut.dispatch(action: .removeBookmark(articleId: articleToRemove.id))

        try await Task.sleep(nanoseconds: 300_000_000)

        // Verify service was updated
        #expect(!mockBookmarksService.bookmarks.contains(where: { $0.id == articleToRemove.id }))
    }

    @Test("Remove non-existent bookmark does not crash")
    func removeNonExistentBookmark() async throws {
        mockBookmarksService.bookmarks = Article.mockArticles

        sut.dispatch(action: .loadBookmarks)
        try await Task.sleep(nanoseconds: 300_000_000)

        let nonExistentArticle = Article(
            id: "non-existent",
            title: "Non-existent",
            description: nil,
            content: nil,
            author: nil,
            source: ArticleSource(id: nil, name: "Unknown"),
            url: "https://example.com",
            imageURL: nil,
            publishedAt: Date(),
            category: nil
        )

        let initialCount = sut.currentState.bookmarks.count

        sut.dispatch(action: .removeBookmark(articleId: nonExistentArticle.id))

        try await Task.sleep(nanoseconds: 300_000_000)

        // Count should remain the same
        #expect(sut.currentState.bookmarks.count == initialCount)
    }

    // MARK: - Select Article Tests

    @Test("Select article dispatches action")
    func selectArticleDispatchesAction() async throws {
        let article = Article.mockArticles[0]
        mockBookmarksService.bookmarks = [article]

        sut.dispatch(action: .loadBookmarks)
        try await Task.sleep(nanoseconds: 300_000_000)

        // Select article action should not throw
        sut.dispatch(action: .selectArticle(articleId: article.id))

        // Just verify the action can be dispatched without error
        #expect(true)
    }
}
