import Foundation
@testable import Pulse
import Testing

@Suite("InterestTopicModel Tests")
struct InterestTopicModelTests {
    private static let baseDate = Date(timeIntervalSince1970: 1_700_000_000)

    private func makeTopic(source: InterestTopic.Source = .seed) -> InterestTopic {
        InterestTopic(
            topicID: "ai",
            displayName: "Artificial Intelligence",
            weight: 4.5,
            category: NewsCategory.technology.rawValue,
            lastReinforcedAt: Self.baseDate,
            createdAt: Self.baseDate.addingTimeInterval(-3600),
            source: source,
        )
    }

    @Test("Init from topic preserves every field")
    func initPreservesAllFields() {
        let topic = makeTopic(source: .extracted)
        let row = InterestTopicModel(from: topic)

        #expect(row.topicID == topic.topicID)
        #expect(row.displayName == topic.displayName)
        #expect(row.weight == topic.weight)
        #expect(row.category == topic.category)
        #expect(row.lastReinforcedAt == topic.lastReinforcedAt)
        #expect(row.createdAt == topic.createdAt)
        #expect(row.sourceRaw == topic.source.rawValue)
    }

    @Test("Round-trip via toTopic restores the original value")
    func roundTripRestoresTopic() throws {
        let topic = makeTopic(source: .manual)
        let row = InterestTopicModel(from: topic)
        let restored = try #require(row.toTopic())
        #expect(restored == topic)
    }

    @Test("toTopic returns nil when sourceRaw is corrupted")
    func toTopicNilOnCorruptedSource() {
        let row = InterestTopicModel(from: makeTopic())
        row.sourceRaw = "not-a-source"
        #expect(row.toTopic() == nil)
    }
}
