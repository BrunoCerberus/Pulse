import Foundation
@testable import Pulse
import Testing

@Suite("MediaDetailViewEvent Tests")
struct MediaDetailViewEventTests {
    @Test("onAppear event") func onAppear() {
        #expect(MediaDetailViewEvent.onAppear == .onAppear)
    }

    @Test("onPlayPauseTapped event") func onPlayPauseTapped() {
        #expect(MediaDetailViewEvent.onPlayPauseTapped == .onPlayPauseTapped)
    }

    @Test("onSeek event") func onSeek() {
        let event = MediaDetailViewEvent.onSeek(progress: 0.5)
        if case let .onSeek(progress) = event { #expect(progress == 0.5) }
    }

    @Test("onSkipBackward event") func onSkipBackward() {
        #expect(MediaDetailViewEvent.onSkipBackward == .onSkipBackward)
    }

    @Test("onSkipForward event") func onSkipForward() {
        #expect(MediaDetailViewEvent.onSkipForward == .onSkipForward)
    }

    @Test("onShareTapped event") func onShareTapped() {
        #expect(MediaDetailViewEvent.onShareTapped == .onShareTapped)
    }

    @Test("onDismissShareSheet event") func onDismissShareSheet() {
        #expect(MediaDetailViewEvent.onDismissShareSheet == .onDismissShareSheet)
    }

    @Test("onBookmarkTapped event") func onBookmarkTapped() {
        #expect(MediaDetailViewEvent.onBookmarkTapped == .onBookmarkTapped)
    }

    @Test("onOpenInBrowser event") func onOpenInBrowser() {
        #expect(MediaDetailViewEvent.onOpenInBrowser == .onOpenInBrowser)
    }

    @Test("onDismissError event") func onDismissError() {
        #expect(MediaDetailViewEvent.onDismissError == .onDismissError)
    }
}
