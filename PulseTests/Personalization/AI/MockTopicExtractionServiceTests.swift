import Foundation
@testable import Pulse
import Testing

@Suite("MockTopicExtractionService Tests")
struct MockTopicExtractionServiceTests {
    @Test("Returns canned tags by default")
    func returnsCannedTags() async throws {
        let sut = MockTopicExtractionService()
        let tags = try await sut.extractTopics(title: "Article", summary: nil)
        #expect(tags == ["technology", "artificial-intelligence"])
    }

    @Test("Records every extract call")
    func recordsCalls() async throws {
        let sut = MockTopicExtractionService()
        _ = try await sut.extractTopics(title: "A", summary: "summary-a")
        _ = try await sut.extractTopics(title: "B", summary: nil)
        #expect(sut.extractCalls.count == 2)
        #expect(sut.extractCalls[0].title == "A")
        #expect(sut.extractCalls[0].summary == "summary-a")
        #expect(sut.extractCalls[1].title == "B")
        #expect(sut.extractCalls[1].summary == nil)
    }

    @Test("resultsByTitle override takes precedence over default extractionResult")
    func resultsByTitleOverride() async throws {
        let sut = MockTopicExtractionService()
        sut.resultsByTitle = ["Special": .success(["custom-tag"])]

        let custom = try await sut.extractTopics(title: "Special", summary: nil)
        let fallback = try await sut.extractTopics(title: "Other", summary: nil)

        #expect(custom == ["custom-tag"])
        #expect(fallback == ["technology", "artificial-intelligence"])
    }

    @Test("extractionResult failure throws")
    func extractionFailureThrows() async {
        struct Boom: Error {}
        let sut = MockTopicExtractionService()
        sut.extractionResult = .failure(Boom())

        await #expect(throws: Boom.self) {
            _ = try await sut.extractTopics(title: "T", summary: nil)
        }
    }
}
