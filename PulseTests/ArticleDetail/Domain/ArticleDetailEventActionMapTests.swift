import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("ArticleDetailEventActionMap Tests")
struct ArticleDetailEventActionMapTests {
    let sut = ArticleDetailEventActionMap()

    @Test("onAppear event maps to onAppear action")
    func onAppearMapping() {
        let action = sut.map(event: .onAppear)
        #expect(action == .onAppear)
    }

    @Test("onBookmarkTapped event maps to toggleBookmark action")
    func onBookmarkTappedMapping() {
        let action = sut.map(event: .onBookmarkTapped)
        #expect(action == .toggleBookmark)
    }

    @Test("onShareTapped event maps to showShareSheet action")
    func onShareTappedMapping() {
        let action = sut.map(event: .onShareTapped)
        #expect(action == .showShareSheet)
    }

    @Test("onSummarizeTapped event maps to showSummarizationSheet action")
    func onSummarizeTappedMapping() {
        let action = sut.map(event: .onSummarizeTapped)
        #expect(action == .showSummarizationSheet)
    }

    @Test("onReadFullTapped event maps to openInBrowser action")
    func onReadFullTappedMapping() {
        let action = sut.map(event: .onReadFullTapped)
        #expect(action == .openInBrowser)
    }

    @Test("onShareSheetDismissed event maps to dismissShareSheet action")
    func onShareSheetDismissedMapping() {
        let action = sut.map(event: .onShareSheetDismissed)
        #expect(action == .dismissShareSheet)
    }

    @Test("onSummarizationSheetDismissed event maps to dismissSummarizationSheet action")
    func onSummarizationSheetDismissedMapping() {
        let action = sut.map(event: .onSummarizationSheetDismissed)
        #expect(action == .dismissSummarizationSheet)
    }

    // MARK: - TTS Event Mappings

    @Test("onDisappear event maps to stopTTS action")
    func onDisappearMapping() {
        let action = sut.map(event: .onDisappear)
        #expect(action == .stopTTS)
    }

    @Test("onListenTapped event maps to startTTS action")
    func onListenTappedMapping() {
        let action = sut.map(event: .onListenTapped)
        #expect(action == .startTTS)
    }

    @Test("onTTSPlayPauseTapped event maps to toggleTTSPlayback action")
    func onTTSPlayPauseTappedMapping() {
        let action = sut.map(event: .onTTSPlayPauseTapped)
        #expect(action == .toggleTTSPlayback)
    }

    @Test("onTTSStopTapped event maps to stopTTS action")
    func onTTSStopTappedMapping() {
        let action = sut.map(event: .onTTSStopTapped)
        #expect(action == .stopTTS)
    }

    @Test("onTTSSpeedTapped event maps to cycleTTSSpeed action")
    func onTTSSpeedTappedMapping() {
        let action = sut.map(event: .onTTSSpeedTapped)
        #expect(action == .cycleTTSSpeed)
    }

    @Test("All events produce non-nil actions")
    func allEventsProduceActions() {
        let events: [ArticleDetailViewEvent] = [
            .onAppear,
            .onDisappear,
            .onBookmarkTapped,
            .onShareTapped,
            .onSummarizeTapped,
            .onReadFullTapped,
            .onShareSheetDismissed,
            .onSummarizationSheetDismissed,
            .onListenTapped,
            .onTTSPlayPauseTapped,
            .onTTSStopTapped,
            .onTTSSpeedTapped,
        ]

        for event in events {
            let action = sut.map(event: event)
            #expect(action != nil, "Event \(event) should produce a non-nil action")
        }
    }
}
