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

        sut.handle(event: .onRemoveBookmark(article))
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(!sut.viewState.bookmarks.contains(where: { $0.id == article.id }))
    }

    @Test("Article tap sets selected article")
    func articleTap() {
        let article = Article.mockArticles[0]

        sut.handle(event: .onArticleTapped(article))

        #expect(sut.selectedArticle?.id == article.id)
    }
}
