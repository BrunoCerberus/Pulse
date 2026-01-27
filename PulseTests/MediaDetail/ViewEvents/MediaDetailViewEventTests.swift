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

    @Test("onSkipBackwardTapped event") func onSkipBackwardTapped() {
        #expect(MediaDetailViewEvent.onSkipBackwardTapped == .onSkipBackwardTapped)
    }

    @Test("onSkipForwardTapped event") func onSkipForwardTapped() {
        #expect(MediaDetailViewEvent.onSkipForwardTapped == .onSkipForwardTapped)
    }

    @Test("onShareTapped event") func onShareTapped() {
        #expect(MediaDetailViewEvent.onShareTapped == .onShareTapped)
    }

    @Test("onShareDismissed event") func onShareDismissed() {
        #expect(MediaDetailViewEvent.onShareDismissed == .onShareDismissed)
    }

    @Test("onBookmarkTapped event") func onBookmarkTapped() {
        #expect(MediaDetailViewEvent.onBookmarkTapped == .onBookmarkTapped)
    }

    @Test("onOpenInBrowserTapped event") func onOpenInBrowserTapped() {
        #expect(MediaDetailViewEvent.onOpenInBrowserTapped == .onOpenInBrowserTapped)
    }

    @Test("onProgressUpdate event") func onProgressUpdate() {
        let event = MediaDetailViewEvent.onProgressUpdate(progress: 0.5, currentTime: 30.0)
        if case let .onProgressUpdate(progress, currentTime) = event {
            #expect(progress == 0.5)
            #expect(currentTime == 30.0)
        }
    }

    @Test("onDurationLoaded event") func onDurationLoaded() {
        let event = MediaDetailViewEvent.onDurationLoaded(120.0)
        if case let .onDurationLoaded(duration) = event {
            #expect(duration == 120.0)
        }
    }

    @Test("onError event") func onError() {
        let event = MediaDetailViewEvent.onError("Test error")
        if case let .onError(message) = event {
            #expect(message == "Test error")
        }
    }
}
