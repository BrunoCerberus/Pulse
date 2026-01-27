import Foundation
@testable import Pulse
import Testing

@Suite("MediaDetailDomainAction Tests")
struct MediaDetailDomainActionTests {
    @Test("onAppear action exists")
    func onAppear() {
        let action = MediaDetailDomainAction.onAppear
        #expect(action == .onAppear)
    }

    @Test("play action exists")
    func play() {
        let action = MediaDetailDomainAction.play
        #expect(action == .play)
    }

    @Test("pause action exists")
    func pause() {
        let action = MediaDetailDomainAction.pause
        #expect(action == .pause)
    }

    @Test("seek with progress")
    func seek() {
        let action = MediaDetailDomainAction.seek(progress: 0.75)

        if case let .seek(progress) = action {
            #expect(progress == 0.75)
        } else {
            Issue.record("Expected seek action")
        }
    }

    @Test("skipBackward with seconds")
    func skipBackward() {
        let action = MediaDetailDomainAction.skipBackward(seconds: 15)

        if case let .skipBackward(seconds) = action {
            #expect(seconds == 15)
        } else {
            Issue.record("Expected skipBackward action")
        }
    }

    @Test("skipForward with seconds")
    func skipForward() {
        let action = MediaDetailDomainAction.skipForward(seconds: 30)

        if case let .skipForward(seconds) = action {
            #expect(seconds == 30)
        } else {
            Issue.record("Expected skipForward action")
        }
    }

    @Test("playbackProgressUpdated with progress and time")
    func playbackProgressUpdated() {
        let action = MediaDetailDomainAction.playbackProgressUpdated(progress: 0.5, currentTime: 60)

        if case let .playbackProgressUpdated(progress, currentTime) = action {
            #expect(progress == 0.5)
            #expect(currentTime == 60)
        } else {
            Issue.record("Expected playbackProgressUpdated action")
        }
    }

    @Test("durationLoaded with time")
    func durationLoaded() {
        let action = MediaDetailDomainAction.durationLoaded(120)

        if case let .durationLoaded(duration) = action {
            #expect(duration == 120)
        } else {
            Issue.record("Expected durationLoaded action")
        }
    }

    @Test("playerLoading action exists")
    func playerLoading() {
        let action = MediaDetailDomainAction.playerLoading
        #expect(action == .playerLoading)
    }

    @Test("playerReady action exists")
    func playerReady() {
        let action = MediaDetailDomainAction.playerReady
        #expect(action == .playerReady)
    }

    @Test("playbackError with message")
    func playbackError() {
        let action = MediaDetailDomainAction.playbackError("Failed to load")

        if case let .playbackError(message) = action {
            #expect(message == "Failed to load")
        } else {
            Issue.record("Expected playbackError action")
        }
    }

    @Test("showShareSheet action exists")
    func showShareSheet() {
        let action = MediaDetailDomainAction.showShareSheet
        #expect(action == .showShareSheet)
    }

    @Test("dismissShareSheet action exists")
    func dismissShareSheet() {
        let action = MediaDetailDomainAction.dismissShareSheet
        #expect(action == .dismissShareSheet)
    }

    @Test("toggleBookmark action exists")
    func toggleBookmark() {
        let action = MediaDetailDomainAction.toggleBookmark
        #expect(action == .toggleBookmark)
    }

    @Test("bookmarkStatusLoaded with true")
    func bookmarkStatusLoadedTrue() {
        let action = MediaDetailDomainAction.bookmarkStatusLoaded(true)

        if case let .bookmarkStatusLoaded(isBookmarked) = action {
            #expect(isBookmarked == true)
        } else {
            Issue.record("Expected bookmarkStatusLoaded action")
        }
    }

    @Test("bookmarkStatusLoaded with false")
    func bookmarkStatusLoadedFalse() {
        let action = MediaDetailDomainAction.bookmarkStatusLoaded(false)

        if case let .bookmarkStatusLoaded(isBookmarked) = action {
            #expect(isBookmarked == false)
        } else {
            Issue.record("Expected bookmarkStatusLoaded action")
        }
    }

    @Test("openInBrowser action exists")
    func openInBrowser() {
        let action = MediaDetailDomainAction.openInBrowser
        #expect(action == .openInBrowser)
    }

    @Test("Same actions are equal")
    func sameActionsAreEqual() {
        #expect(MediaDetailDomainAction.onAppear == MediaDetailDomainAction.onAppear)
        #expect(MediaDetailDomainAction.play == MediaDetailDomainAction.play)
        #expect(MediaDetailDomainAction.pause == MediaDetailDomainAction.pause)
        #expect(MediaDetailDomainAction.seek(progress: 0.5) == MediaDetailDomainAction.seek(progress: 0.5))
        #expect(MediaDetailDomainAction.skipBackward(seconds: 15) == MediaDetailDomainAction.skipBackward(seconds: 15))
        #expect(MediaDetailDomainAction.skipForward(seconds: 30) == MediaDetailDomainAction.skipForward(seconds: 30))
        #expect(MediaDetailDomainAction.playbackProgressUpdated(progress: 0.5, currentTime: 60) == MediaDetailDomainAction.playbackProgressUpdated(progress: 0.5, currentTime: 60))
        #expect(MediaDetailDomainAction.durationLoaded(120) == MediaDetailDomainAction.durationLoaded(120))
        #expect(MediaDetailDomainAction.playerLoading == MediaDetailDomainAction.playerLoading)
        #expect(MediaDetailDomainAction.playerReady == MediaDetailDomainAction.playerReady)
        #expect(MediaDetailDomainAction.playbackError("test") == MediaDetailDomainAction.playbackError("test"))
        #expect(MediaDetailDomainAction.showShareSheet == MediaDetailDomainAction.showShareSheet)
        #expect(MediaDetailDomainAction.dismissShareSheet == MediaDetailDomainAction.dismissShareSheet)
        #expect(MediaDetailDomainAction.toggleBookmark == MediaDetailDomainAction.toggleBookmark)
        #expect(MediaDetailDomainAction.bookmarkStatusLoaded(true) == MediaDetailDomainAction.bookmarkStatusLoaded(true))
        #expect(MediaDetailDomainAction.openInBrowser == MediaDetailDomainAction.openInBrowser)
    }

    @Test("Different actions are not equal")
    func differentActionsAreNotEqual() {
        #expect(MediaDetailDomainAction.play != MediaDetailDomainAction.pause)
        #expect(MediaDetailDomainAction.seek(progress: 0.5) != MediaDetailDomainAction.seek(progress: 0.6))
        #expect(MediaDetailDomainAction.skipBackward(seconds: 15) != MediaDetailDomainAction.skipBackward(seconds: 30))
        #expect(MediaDetailDomainAction.skipForward(seconds: 10) != MediaDetailDomainAction.skipForward(seconds: 20))
        #expect(MediaDetailDomainAction.playbackProgressUpdated(progress: 0.5, currentTime: 60) != MediaDetailDomainAction.playbackProgressUpdated(progress: 0.6, currentTime: 60))
        #expect(MediaDetailDomainAction.durationLoaded(120) != MediaDetailDomainAction.durationLoaded(180))
        #expect(MediaDetailDomainAction.playbackError("a") != MediaDetailDomainAction.playbackError("b"))
        #expect(MediaDetailDomainAction.showShareSheet != MediaDetailDomainAction.dismissShareSheet)
        #expect(MediaDetailDomainAction.bookmarkStatusLoaded(true) != MediaDetailDomainAction.bookmarkStatusLoaded(false))
    }
}
