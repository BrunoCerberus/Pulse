import Foundation
@testable import Pulse
import Testing

@Suite("MediaViewEvent Tests")
struct MediaViewEventTests {
    @Test("onAppear event") func onAppear() {
        #expect(MediaViewEvent.onAppear == .onAppear)
    }

    @Test("onRefresh event") func onRefresh() {
        #expect(MediaViewEvent.onRefresh == .onRefresh)
    }

    @Test("onLoadMore event") func onLoadMore() {
        #expect(MediaViewEvent.onLoadMore == .onLoadMore)
    }

    @Test("onMediaTapped event") func onMediaTapped() {
        let event = MediaViewEvent.onMediaTapped(mediaId: "id")
        if case let .onMediaTapped(mediaId) = event { #expect(mediaId == "id") }
    }

    @Test("onMediaTypeSelected event") func onMediaTypeSelected() {
        let event = MediaViewEvent.onMediaTypeSelected(.video)
        if case let .onMediaTypeSelected(type) = event { #expect(type == .video) }
    }

    @Test("onMediaNavigated event") func onMediaNavigated() {
        #expect(MediaViewEvent.onMediaNavigated == .onMediaNavigated)
    }

    @Test("onShareTapped event") func onShareTapped() {
        let event = MediaViewEvent.onShareTapped(mediaId: "id")
        if case let .onShareTapped(mediaId) = event { #expect(mediaId == "id") }
    }

    @Test("onShareDismissed event") func onShareDismissed() {
        #expect(MediaViewEvent.onShareDismissed == .onShareDismissed)
    }

    @Test("onPlayTapped event") func onPlayTapped() {
        let event = MediaViewEvent.onPlayTapped(mediaId: "id")
        if case let .onPlayTapped(mediaId) = event { #expect(mediaId == "id") }
    }

    @Test("onPlayDismissed event") func onPlayDismissed() {
        #expect(MediaViewEvent.onPlayDismissed == .onPlayDismissed)
    }
}
