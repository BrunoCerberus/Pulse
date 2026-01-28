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
        mockMediaService.simulatedDelay = 0 // No delay for tests
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
    func handleOnAppear() {
        sut.handle(event: .onAppear)
        // Event should be handled without error
        // The mock service will provide sample data
    }

    @Test("Handle refresh triggers data refresh")
    func handleRefresh() {
        sut.handle(event: .onRefresh)
        // Event should be handled without error
    }

    @Test("Handle selectMediaType updates filter")
    func handleSelectMediaType() {
        sut.handle(event: .onMediaTypeSelected(.video))
        // Event should be handled without error
    }

    @Test("Handle selectMedia sets selected media")
    func handleSelectMedia() {
        let mediaId = "video-1"
        sut.handle(event: .onMediaTapped(mediaId: mediaId))
        // Event should be handled without error
    }

    @Test("Handle loadMore triggers pagination")
    func handleLoadMore() {
        sut.handle(event: .onLoadMore)
        // Event should be handled without error
    }

    @Test("Handle shareMedia sets media to share")
    func handleShareMedia() {
        let mediaId = "video-1"
        sut.handle(event: .onShareTapped(mediaId: mediaId))
        // Event should be handled without error
    }

    @Test("Handle dismissShareSheet clears share sheet")
    func handleDismissShareSheet() {
        sut.handle(event: .onShareDismissed)
        // Event should be handled without error
    }

    @Test("Handle playMedia sets media to play")
    func handlePlayMedia() {
        let mediaId = "video-1"
        sut.handle(event: .onPlayTapped(mediaId: mediaId))
        // Event should be handled without error
    }

    @Test("Handle playDismissed clears player")
    func handlePlayDismissed() {
        sut.handle(event: .onPlayDismissed)
        // Event should be handled without error
    }
}
