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
        let event = MediaViewEvent.onMediaTapped(articleId: "id")
        if case let .onMediaTapped(id) = event { #expect(id == "id") }
    }

    @Test("onMediaTypeChanged event") func onMediaTypeChanged() {
        let event = MediaViewEvent.onMediaTypeChanged(.video)
        if case let .onMediaTypeChanged(type) = event { #expect(type == .video) }
    }

    @Test("onShareTapped event") func onShareTapped() {
        let event = MediaViewEvent.onShareTapped(articleId: "id")
        if case let .onShareTapped(id) = event { #expect(id == "id") }
    }

    @Test("onDismissShareSheet event") func onDismissShareSheet() {
        #expect(MediaViewEvent.onDismissShareSheet == .onDismissShareSheet)
    }

    @Test("onPlayTapped event") func onPlayTapped() {
        let event = MediaViewEvent.onPlayTapped(articleId: "id")
        if case let .onPlayTapped(id) = event { #expect(id == "id") }
    }
}
