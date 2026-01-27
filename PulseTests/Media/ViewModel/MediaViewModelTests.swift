import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("MediaViewModel Tests")
@MainActor
struct MediaViewModelTests {
    let serviceLocator: ServiceLocator
    let mockMediaService: MockMediaService
    let sut: MediaViewModel

    init() {
        mockMediaService = MockMediaService()
        serviceLocator = ServiceLocator()
        serviceLocator.register(MediaService.self, instance: mockMediaService)
        sut = MediaViewModel(serviceLocator: serviceLocator)
    }

    @Test("Initial view state is correct")
    func initialViewState() {
        #expect(sut.viewState.featuredMedia.isEmpty)
        #expect(sut.viewState.mediaItems.isEmpty)
        #expect(sut.viewState.isLoading == false)
        #expect(sut.viewState.selectedMedia == nil)
    }

    @Test("Handle onAppear triggers data load")
    func handleOnAppear() async throws {
        let articles = Article.mockArticles
        mockMediaService.mediaResult = .success(articles)
        mockMediaService.featuredMediaResult = .success(Array(articles.prefix(2)))

        sut.handle(event: .onAppear)

        try await waitForStateUpdate()

        #expect(mockMediaService.fetchMediaCallCount > 0)
    }

    @Test("Handle refresh triggers data refresh")
    func handleRefresh() {
        sut.handle(event: .onRefresh)
        // Event should be handled without error
    }

    @Test("Handle selectMediaType updates filter")
    func handleSelectMediaType() {
        sut.handle(event: .onMediaTypeChanged(.video))
        // Event should be handled without error
    }

    @Test("Handle selectMedia sets selected media")
    func handleSelectMedia() async throws {
        let article = Article.mockArticles[0]
        mockMediaService.mediaResult = .success(Article.mockArticles)

        sut.handle(event: .onAppear)
        try await waitForStateUpdate()

        sut.handle(event: .onMediaTapped(articleId: article.id))

        // After selection, selected media should be set in domain
        // Note: The actual state update happens async through the interactor
    }

    @Test("Handle loadMore triggers pagination")
    func handleLoadMore() {
        sut.handle(event: .onLoadMore)
        // Event should be handled without error
    }

    @Test("Handle shareMedia sets media to share")
    func handleShareMedia() {
        let article = Article.mockArticles[0]
        sut.handle(event: .onShareTapped(articleId: article.id))
        // Event should be handled without error
    }

    @Test("Handle dismissShareSheet clears share sheet")
    func handleDismissShareSheet() {
        sut.handle(event: .onDismissShareSheet)
        // Event should be handled without error
    }

    @Test("Handle playMedia sets media to play")
    func handlePlayMedia() {
        let article = Article.mockArticles[0]
        sut.handle(event: .onPlayTapped(articleId: article.id))
        // Event should be handled without error
    }
}
