import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("MediaEventActionMap Tests")
struct MediaEventActionMapTests {
    let sut = MediaEventActionMap()

    @Test("onAppear maps to loadInitialData")
    func testOnAppear() {
        #expect(sut.map(event: .onAppear) == .loadInitialData)
    }

    @Test("onRefresh maps to refresh")
    func testOnRefresh() {
        #expect(sut.map(event: .onRefresh) == .refresh)
    }

    @Test("onLoadMore maps to loadMoreMedia")
    func testOnLoadMore() {
        #expect(sut.map(event: .onLoadMore) == .loadMoreMedia)
    }

    @Test("onMediaTypeSelected maps to selectMediaType")
    func testOnMediaTypeSelected() {
        #expect(sut.map(event: .onMediaTypeSelected(.video)) == .selectMediaType(.video))
        #expect(sut.map(event: .onMediaTypeSelected(.podcast)) == .selectMediaType(.podcast))
        #expect(sut.map(event: .onMediaTypeSelected(nil)) == .selectMediaType(nil))
    }

    @Test("onMediaTapped maps to selectMedia")
    func testOnMediaTapped() {
        let mediaId = "test-media-id"
        #expect(sut.map(event: .onMediaTapped(mediaId: mediaId)) == .selectMedia(mediaId: mediaId))
    }

    @Test("onMediaNavigated maps to clearSelectedMedia")
    func testOnMediaNavigated() {
        #expect(sut.map(event: .onMediaNavigated) == .clearSelectedMedia)
    }

    @Test("onShareTapped maps to shareMedia")
    func testOnShareTapped() {
        let mediaId = "test-media-id"
        #expect(sut.map(event: .onShareTapped(mediaId: mediaId)) == .shareMedia(mediaId: mediaId))
    }

    @Test("onShareDismissed maps to clearMediaToShare")
    func testOnShareDismissed() {
        #expect(sut.map(event: .onShareDismissed) == .clearMediaToShare)
    }

    @Test("onPlayTapped maps to playMedia")
    func testOnPlayTapped() {
        let mediaId = "test-media-id"
        #expect(sut.map(event: .onPlayTapped(mediaId: mediaId)) == .playMedia(mediaId: mediaId))
    }

    @Test("onPlayDismissed maps to clearMediaToPlay")
    func testOnPlayDismissed() {
        #expect(sut.map(event: .onPlayDismissed) == .clearMediaToPlay)
    }

    @Test("All events map to correct actions")
    func allEventsMappingToCorrectActions() {
        let mediaId = "video-1"

        #expect(sut.map(event: .onAppear) == .loadInitialData)
        #expect(sut.map(event: .onRefresh) == .refresh)
        #expect(sut.map(event: .onLoadMore) == .loadMoreMedia)
        #expect(sut.map(event: .onMediaTypeSelected(.video)) == .selectMediaType(.video))
        #expect(sut.map(event: .onMediaTapped(mediaId: mediaId)) == .selectMedia(mediaId: mediaId))
        #expect(sut.map(event: .onMediaNavigated) == .clearSelectedMedia)
        #expect(sut.map(event: .onShareTapped(mediaId: mediaId)) == .shareMedia(mediaId: mediaId))
        #expect(sut.map(event: .onShareDismissed) == .clearMediaToShare)
        #expect(sut.map(event: .onPlayTapped(mediaId: mediaId)) == .playMedia(mediaId: mediaId))
        #expect(sut.map(event: .onPlayDismissed) == .clearMediaToPlay)
    }
}
