import Foundation
@testable import Pulse
import Testing

@Suite("MediaType Tests")
struct MediaTypeTests {
    @Test("Video type exists")
    func videoType() {
        let type = MediaType.video
        #expect(type == .video)
    }

    @Test("Podcast type exists")
    func podcastType() {
        let type = MediaType.podcast
        #expect(type == .podcast)
    }

    @Test("All cases are available")
    func allCases() {
        let allCases = MediaType.allCases
        #expect(allCases.count == 2)
        #expect(allCases.contains(.video))
        #expect(allCases.contains(.podcast))
    }

    @Test("Same types are equal")
    func sameTypesAreEqual() {
        #expect(MediaType.video == MediaType.video)
        #expect(MediaType.podcast == MediaType.podcast)
    }

    @Test("Different types are not equal")
    func differentTypesAreNotEqual() {
        #expect(MediaType.video != MediaType.podcast)
    }

    @Test("Can be used in switch statement")
    func switchStatement() {
        let type: MediaType = .video

        switch type {
        case .video:
            #expect(true)
        case .podcast:
            Issue.record("Expected video type")
        }
    }
}
