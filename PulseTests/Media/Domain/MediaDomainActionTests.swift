import Foundation
@testable import Pulse
import Testing

@Suite("MediaDomainAction Tests")
struct MediaDomainActionTests {
    @Test("loadInitialData action exists")
    func loadInitialDataAction() {
        let action = MediaDomainAction.loadInitialData
        #expect(action == .loadInitialData)
    }

    @Test("loadMoreMedia action exists")
    func loadMoreMediaAction() {
        let action = MediaDomainAction.loadMoreMedia
        #expect(action == .loadMoreMedia)
    }

    @Test("refresh action exists")
    func refreshAction() {
        let action = MediaDomainAction.refresh
        #expect(action == .refresh)
    }

    @Test("selectMediaType with video")
    func selectMediaTypeVideo() {
        let action = MediaDomainAction.selectMediaType(.video)

        if case let .selectMediaType(type) = action {
            #expect(type == .video)
        } else {
            Issue.record("Expected selectMediaType action")
        }
    }

    @Test("selectMediaType with podcast")
    func selectMediaTypePodcast() {
        let action = MediaDomainAction.selectMediaType(.podcast)

        if case let .selectMediaType(type) = action {
            #expect(type == .podcast)
        } else {
            Issue.record("Expected selectMediaType action")
        }
    }

    @Test("selectMediaType with nil")
    func selectMediaTypeNil() {
        let action = MediaDomainAction.selectMediaType(nil)

        if case let .selectMediaType(type) = action {
            #expect(type == nil)
        } else {
            Issue.record("Expected selectMediaType action")
        }
    }

    @Test("selectMedia with media ID")
    func selectMedia() {
        let action = MediaDomainAction.selectMedia(mediaId: "media-123")

        if case let .selectMedia(mediaId) = action {
            #expect(mediaId == "media-123")
        } else {
            Issue.record("Expected selectMedia action")
        }
    }

    @Test("clearSelectedMedia action exists")
    func clearSelectedMedia() {
        let action = MediaDomainAction.clearSelectedMedia
        #expect(action == .clearSelectedMedia)
    }

    @Test("shareMedia with media ID")
    func shareMedia() {
        let action = MediaDomainAction.shareMedia(mediaId: "media-456")

        if case let .shareMedia(mediaId) = action {
            #expect(mediaId == "media-456")
        } else {
            Issue.record("Expected shareMedia action")
        }
    }

    @Test("clearMediaToShare action exists")
    func clearMediaToShare() {
        let action = MediaDomainAction.clearMediaToShare
        #expect(action == .clearMediaToShare)
    }

    @Test("playMedia with media ID")
    func playMedia() {
        let action = MediaDomainAction.playMedia(mediaId: "media-789")

        if case let .playMedia(mediaId) = action {
            #expect(mediaId == "media-789")
        } else {
            Issue.record("Expected playMedia action")
        }
    }

    @Test("clearMediaToPlay action exists")
    func clearMediaToPlay() {
        let action = MediaDomainAction.clearMediaToPlay
        #expect(action == .clearMediaToPlay)
    }

    @Test("Same actions are equal")
    func sameActionsAreEqual() {
        #expect(MediaDomainAction.loadInitialData == MediaDomainAction.loadInitialData)
        #expect(MediaDomainAction.selectMedia(mediaId: "id") == MediaDomainAction.selectMedia(mediaId: "id"))
        #expect(MediaDomainAction.selectMediaType(.video) == MediaDomainAction.selectMediaType(.video))
    }

    @Test("Different actions are not equal")
    func differentActionsAreNotEqual() {
        #expect(MediaDomainAction.loadInitialData != MediaDomainAction.refresh)
        #expect(MediaDomainAction.selectMedia(mediaId: "1") != MediaDomainAction.selectMedia(mediaId: "2"))
        #expect(MediaDomainAction.selectMediaType(.video) != MediaDomainAction.selectMediaType(.podcast))
    }
}
