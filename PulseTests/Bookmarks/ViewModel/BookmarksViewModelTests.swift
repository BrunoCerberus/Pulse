import Combine
import Foundation
@testable import Pulse
import Testing

@Suite("BookmarksViewModel Tests")
@MainActor
struct BookmarksViewModelTests {
    let mockBookmarksService: MockBookmarksService
    let mockStorageService: MockStorageService
    let serviceLocator: ServiceLocator
    let sut: BookmarksViewModel

    init() {
        mockBookmarksService = MockBookmarksService()
        mockStorageService = MockStorageService()
        serviceLocator = ServiceLocator()

        serviceLocator.register(BookmarksService.self, instance: mockBookmarksService)
        serviceLocator.register(StorageService.self, instance: mockStorageService)

        sut = BookmarksViewModel(serviceLocator: serviceLocator)
    }

    @Test("Initial view state is correct")
    func initialViewState() {
        let state = sut.viewState
        #expect(state.bookmarks.isEmpty)
        #expect(!state.isLoading)
        #expect(state.errorMessage == nil)
        // showEmptyState is true because bindings fire immediately with empty domain state
        #expect(state.showEmptyState)
    }

    @Test("Load bookmarks updates state")
    func loadBookmarks() async throws {
        mockBookmarksService.bookmarks = Article.mockArticles

        sut.handle(event: .onAppear)

        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(!sut.viewState.bookmarks.isEmpty)
    }

    @Test("Empty bookmarks shows empty state")
    func emptyBookmarks() async throws {
        mockBookmarksService.bookmarks = []

        sut.handle(event: .onAppear)

        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(sut.viewState.showEmptyState)
    }

    @Test("Remove bookmark updates list")
    func removeBookmark() async throws {
        let article = Article.mockArticles[0]
        mockBookmarksService.bookmarks = [article]

        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 300_000_000)

        sut.handle(event: .onRemoveBookmark(articleId: article.id))
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(!sut.viewState.bookmarks.contains(where: { $0.id == article.id }))
    }

    @Test("Article tap sets selected article")
    func articleTap() async throws {
        let article = Article.mockArticles[0]
        mockBookmarksService.bookmarks = [article]

        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 300_000_000)

        sut.handle(event: .onArticleTapped(articleId: article.id))

        try await Task.sleep(nanoseconds: 50_000_000)

        #expect(sut.viewState.selectedArticle?.id == article.id)
    }

    // MARK: - Refresh Tests

    @Test("Refresh reloads bookmarks")
    func refreshReloadsBookmarks() async throws {
        mockBookmarksService.bookmarks = Article.mockArticles

        sut.handle(event: .onRefresh)

        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(!sut.viewState.bookmarks.isEmpty)
        #expect(!sut.viewState.isRefreshing)
    }

    @Test("Refresh sets refreshing state")
    func refreshSetsRefreshingState() async throws {
        var cancellables = Set<AnyCancellable>()
        var refreshingStates: [Bool] = []

        sut.$viewState
            .map(\.isRefreshing)
            .sink { isRefreshing in
                refreshingStates.append(isRefreshing)
            }
            .store(in: &cancellables)

        mockBookmarksService.bookmarks = Article.mockArticles

        sut.handle(event: .onRefresh)

        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(refreshingStates.contains(true))
        #expect(refreshingStates.last == false)
    }

    // MARK: - Loading State Tests

    @Test("Loading sets loading state")
    func loadingSetsLoadingState() async throws {
        var cancellables = Set<AnyCancellable>()
        var loadingStates: [Bool] = []

        sut.$viewState
            .map(\.isLoading)
            .sink { isLoading in
                loadingStates.append(isLoading)
            }
            .store(in: &cancellables)

        mockBookmarksService.bookmarks = Article.mockArticles

        sut.handle(event: .onAppear)

        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(loadingStates.contains(true))
        #expect(loadingStates.last == false)
    }

    // MARK: - Article Tap Tests

    @Test("Article tap saves to reading history")
    func articleTapSavesToHistory() async throws {
        let article = Article.mockArticles[0]
        mockBookmarksService.bookmarks = [article]

        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 300_000_000)

        sut.handle(event: .onArticleTapped(articleId: article.id))

        try await Task.sleep(nanoseconds: 200_000_000)

        let history = try await mockStorageService.fetchReadingHistory()
        #expect(history.contains(where: { $0.id == article.id }))
    }

    // MARK: - Remove Bookmark Tests

    @Test("Remove all bookmarks shows empty state")
    func removeAllBookmarksShowsEmptyState() async throws {
        let article = Article.mockArticles[0]
        mockBookmarksService.bookmarks = [article]

        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(!sut.viewState.showEmptyState)

        sut.handle(event: .onRemoveBookmark(articleId: article.id))
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.viewState.showEmptyState)
    }

    @Test("Remove one of multiple bookmarks")
    func removeOneOfMultipleBookmarks() async throws {
        mockBookmarksService.bookmarks = Article.mockArticles

        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 300_000_000)

        let initialCount = sut.viewState.bookmarks.count
        let articleToRemove = Article.mockArticles[0]

        sut.handle(event: .onRemoveBookmark(articleId: articleToRemove.id))
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.viewState.bookmarks.count == initialCount - 1)
        #expect(!sut.viewState.showEmptyState)
    }

    // MARK: - View State Transformation Tests

    @Test("Bookmarks are transformed to ArticleViewItems")
    func bookmarksTransformedToViewItems() async throws {
        mockBookmarksService.bookmarks = Article.mockArticles

        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(!sut.viewState.bookmarks.isEmpty)
        let firstBookmark = sut.viewState.bookmarks[0]
        #expect(!firstBookmark.id.isEmpty)
        #expect(!firstBookmark.title.isEmpty)
    }

    @Test("View state updates through publisher binding")
    func viewStateUpdatesThroughPublisher() async throws {
        var cancellables = Set<AnyCancellable>()
        var states: [BookmarksViewState] = []

        sut.$viewState
            .sink { state in
                states.append(state)
            }
            .store(in: &cancellables)

        mockBookmarksService.bookmarks = Article.mockArticles

        sut.handle(event: .onAppear)

        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(states.count > 1)
    }

    // MARK: - Empty State Tests

    @Test("Empty state shown after loading when no bookmarks")
    func emptyStateShownAfterLoading() async throws {
        mockBookmarksService.bookmarks = []

        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 500_000_000)

        // After loading completes with empty results, showEmptyState should be true
        #expect(!sut.viewState.isLoading)
        #expect(sut.viewState.bookmarks.isEmpty)
        #expect(sut.viewState.showEmptyState)
    }

    @Test("Empty state hidden when bookmarks exist")
    func emptyStateHiddenWhenBookmarksExist() async throws {
        mockBookmarksService.bookmarks = Article.mockArticles

        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(!sut.viewState.isLoading)
        #expect(!sut.viewState.bookmarks.isEmpty)
        #expect(!sut.viewState.showEmptyState)
    }
}
