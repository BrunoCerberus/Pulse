import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("MediaDetailEventActionMap Tests")
struct MediaDetailEventActionMapTests {
    let sut = MediaDetailEventActionMap()

    // MARK: - Lifecycle Events

    @Test("onAppear maps to onAppear action")
    func testOnAppear() {
        #expect(sut.map(event: .onAppear) == .onAppear)
    }

    // MARK: - Playback Control Events

    @Test("onPlayPauseTapped returns nil (handled by ViewModel)")
    func testOnPlayPauseTapped() {
        #expect(sut.map(event: .onPlayPauseTapped) == nil)
    }

    @Test("onSeek maps to seek action")
    func testOnSeek() {
        #expect(sut.map(event: .onSeek(progress: 0.5)) == .seek(to: 0.5))
        #expect(sut.map(event: .onSeek(progress: 0.0)) == .seek(to: 0.0))
        #expect(sut.map(event: .onSeek(progress: 1.0)) == .seek(to: 1.0))
    }

    @Test("onSkipBackwardTapped maps to skipBackward with 15 seconds")
    func testOnSkipBackwardTapped() {
        #expect(sut.map(event: .onSkipBackwardTapped) == .skipBackward(seconds: 15))
    }

    @Test("onSkipForwardTapped maps to skipForward with 30 seconds")
    func testOnSkipForwardTapped() {
        #expect(sut.map(event: .onSkipForwardTapped) == .skipForward(seconds: 30))
    }

    // MARK: - Playback Events from Player

    @Test("onProgressUpdate maps to playbackProgressUpdated")
    func testOnProgressUpdate() {
        let action = sut.map(event: .onProgressUpdate(progress: 0.75, currentTime: 450))
        #expect(action == .playbackProgressUpdated(progress: 0.75, currentTime: 450))
    }

    @Test("onDurationLoaded maps to durationLoaded")
    func testOnDurationLoaded() {
        #expect(sut.map(event: .onDurationLoaded(3600)) == .durationLoaded(3600))
    }

    @Test("onPlayerLoading maps to playerLoading")
    func testOnPlayerLoading() {
        #expect(sut.map(event: .onPlayerLoading) == .playerLoading)
    }

    @Test("onPlayerReady maps to playerReady")
    func testOnPlayerReady() {
        #expect(sut.map(event: .onPlayerReady) == .playerReady)
    }

    @Test("onError maps to playbackError")
    func testOnError() {
        #expect(sut.map(event: .onError("Video unavailable")) == .playbackError("Video unavailable"))
    }

    // MARK: - Action Events

    @Test("onShareTapped maps to showShareSheet")
    func testOnShareTapped() {
        #expect(sut.map(event: .onShareTapped) == .showShareSheet)
    }

    @Test("onShareDismissed maps to dismissShareSheet")
    func testOnShareDismissed() {
        #expect(sut.map(event: .onShareDismissed) == .dismissShareSheet)
    }

    @Test("onBookmarkTapped maps to toggleBookmark")
    func testOnBookmarkTapped() {
        #expect(sut.map(event: .onBookmarkTapped) == .toggleBookmark)
    }

    @Test("onOpenInBrowserTapped maps to openInBrowser")
    func testOnOpenInBrowserTapped() {
        #expect(sut.map(event: .onOpenInBrowserTapped) == .openInBrowser)
    }

    // MARK: - Comprehensive Event Mapping Test

    @Test("All events map to correct actions")
    func allEventsMappingToCorrectActions() {
        // Lifecycle
        #expect(sut.map(event: .onAppear) == .onAppear)

        // Playback control
        #expect(sut.map(event: .onPlayPauseTapped) == nil)
        #expect(sut.map(event: .onSeek(progress: 0.25)) == .seek(to: 0.25))
        #expect(sut.map(event: .onSkipBackwardTapped) == .skipBackward(seconds: 15))
        #expect(sut.map(event: .onSkipForwardTapped) == .skipForward(seconds: 30))

        // Playback events
        #expect(sut.map(event: .onProgressUpdate(progress: 0.5, currentTime: 300)) == .playbackProgressUpdated(progress: 0.5, currentTime: 300))
        #expect(sut.map(event: .onDurationLoaded(600)) == .durationLoaded(600))
        #expect(sut.map(event: .onPlayerLoading) == .playerLoading)
        #expect(sut.map(event: .onPlayerReady) == .playerReady)
        #expect(sut.map(event: .onError("Error")) == .playbackError("Error"))

        // Actions
        #expect(sut.map(event: .onShareTapped) == .showShareSheet)
        #expect(sut.map(event: .onShareDismissed) == .dismissShareSheet)
        #expect(sut.map(event: .onBookmarkTapped) == .toggleBookmark)
        #expect(sut.map(event: .onOpenInBrowserTapped) == .openInBrowser)
    }
}
