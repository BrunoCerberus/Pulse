import Foundation
@testable import Pulse
import Testing

@Suite("MediaType Tests")
struct MediaTypeTests {
    // MARK: - Raw Value Tests

    @Test("Video raw value is video")
    func videoRawValue() {
        #expect(MediaType.video.rawValue == "video")
    }

    @Test("Podcast raw value is podcast")
    func podcastRawValue() {
        #expect(MediaType.podcast.rawValue == "podcast")
    }

    // MARK: - ID Tests

    @Test("ID matches raw value for video")
    func videoIdMatchesRawValue() {
        #expect(MediaType.video.id == "video")
    }

    @Test("ID matches raw value for podcast")
    func podcastIdMatchesRawValue() {
        #expect(MediaType.podcast.id == "podcast")
    }

    // MARK: - Display Name Tests

    @Test("Video display name is not empty")
    func videoDisplayName() {
        let name = MediaType.video.displayName
        #expect(!name.isEmpty)
    }

    @Test("Podcast display name is not empty")
    func podcastDisplayName() {
        let name = MediaType.podcast.displayName
        #expect(!name.isEmpty)
    }

    @Test("Display names are different for each type")
    func displayNamesAreDifferent() {
        #expect(MediaType.video.displayName != MediaType.podcast.displayName)
    }

    // MARK: - Icon Tests

    @Test("Video icon is play rectangle fill")
    func videoIcon() {
        #expect(MediaType.video.icon == "play.rectangle.fill")
    }

    @Test("Podcast icon is headphones")
    func podcastIcon() {
        #expect(MediaType.podcast.icon == "headphones")
    }

    // MARK: - Category Slug Tests

    @Test("Video category slug is videos")
    func videoCategorySlug() {
        #expect(MediaType.video.categorySlug == "videos")
    }

    @Test("Podcast category slug is podcasts")
    func podcastCategorySlug() {
        #expect(MediaType.podcast.categorySlug == "podcasts")
    }

    // MARK: - Init From String Tests

    @Test("Init from lowercase video string")
    func initFromLowercaseVideo() {
        let type = MediaType(fromString: "video")
        #expect(type == .video)
    }

    @Test("Init from uppercase VIDEO string")
    func initFromUppercaseVideo() {
        let type = MediaType(fromString: "VIDEO")
        #expect(type == .video)
    }

    @Test("Init from mixed case Video string")
    func initFromMixedCaseVideo() {
        let type = MediaType(fromString: "Video")
        #expect(type == .video)
    }

    @Test("Init from lowercase podcast string")
    func initFromLowercasePodcast() {
        let type = MediaType(fromString: "podcast")
        #expect(type == .podcast)
    }

    @Test("Init from uppercase PODCAST string")
    func initFromUppercasePodcast() {
        let type = MediaType(fromString: "PODCAST")
        #expect(type == .podcast)
    }

    @Test("Init from nil string returns nil")
    func initFromNilString() {
        let type = MediaType(fromString: nil)
        #expect(type == nil)
    }

    @Test("Init from empty string returns nil")
    func initFromEmptyString() {
        let type = MediaType(fromString: "")
        #expect(type == nil)
    }

    @Test("Init from invalid string returns nil")
    func initFromInvalidString() {
        let type = MediaType(fromString: "article")
        #expect(type == nil)
    }

    @Test("Init from gibberish returns nil")
    func initFromGibberish() {
        let type = MediaType(fromString: "xyz123")
        #expect(type == nil)
    }

    // MARK: - CaseIterable Tests

    @Test("All cases contains both types")
    func allCases() {
        #expect(MediaType.allCases.count == 2)
        #expect(MediaType.allCases.contains(.video))
        #expect(MediaType.allCases.contains(.podcast))
    }

    // MARK: - Equatable Tests

    @Test("Same types are equal")
    func sameTypesAreEqual() {
        #expect(MediaType.video == MediaType.video)
        #expect(MediaType.podcast == MediaType.podcast)
    }

    @Test("Different types are not equal")
    func differentTypesAreNotEqual() {
        #expect(MediaType.video != MediaType.podcast)
    }

    // MARK: - Hashable Tests

    @Test("Can be used as dictionary key")
    func hashable() {
        var dict: [MediaType: String] = [:]
        dict[.video] = "Videos"
        dict[.podcast] = "Podcasts"
        #expect(dict[.video] == "Videos")
        #expect(dict[.podcast] == "Podcasts")
    }

    @Test("Hash values are consistent")
    func hashValuesConsistent() {
        let hash1 = MediaType.video.hashValue
        let hash2 = MediaType.video.hashValue
        #expect(hash1 == hash2)
    }

    // MARK: - Codable Tests

    @Test("Can encode and decode video")
    func codableVideo() throws {
        let original = MediaType.video
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MediaType.self, from: data)
        #expect(decoded == original)
    }

    @Test("Can encode and decode podcast")
    func codablePodcast() throws {
        let original = MediaType.podcast
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MediaType.self, from: data)
        #expect(decoded == original)
    }

    // MARK: - Color Tests

    @Test("Video and podcast have different colors")
    func differentColors() {
        #expect(MediaType.video.color != MediaType.podcast.color)
    }

    // MARK: - Switch Tests

    @Test("Can be used in switch statement")
    func switchStatement() {
        let type: MediaType = .video

        switch type {
        case .video:
            #expect(Bool(true))
        case .podcast:
            Issue.record("Expected video type")
        }
    }
}
