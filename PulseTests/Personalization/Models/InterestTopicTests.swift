import Foundation
@testable import Pulse
import Testing

@Suite("InterestTopic Tests")
struct InterestTopicTests {
    private static let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)

    private func makeTopic(
        weight: Double = 1.0,
        lastReinforcedAt: Date = Self.referenceDate,
    ) -> InterestTopic {
        InterestTopic(
            topicID: "ai",
            displayName: "AI",
            weight: weight,
            category: nil,
            lastReinforcedAt: lastReinforcedAt,
            createdAt: lastReinforcedAt,
            source: .extracted,
        )
    }

    @Test("currentWeight equals stored weight when no time has passed")
    func currentWeightAtSameInstant() {
        let topic = makeTopic(weight: 5.0)
        #expect(topic.currentWeight(at: Self.referenceDate) == 5.0)
    }

    @Test("currentWeight halves after one half-life")
    func currentWeightHalvesAtHalfLife() {
        let topic = makeTopic(weight: 1.0)
        let oneHalfLifeLater = Self.referenceDate.addingTimeInterval(86400 * 30)
        let result = topic.currentWeight(at: oneHalfLifeLater, halfLifeDays: 30)
        #expect(abs(result - 0.5) < 0.0001)
    }

    @Test("currentWeight quarters after two half-lives")
    func currentWeightQuartersAtTwoHalfLives() {
        let topic = makeTopic(weight: 1.0)
        let twoHalfLivesLater = Self.referenceDate.addingTimeInterval(86400 * 60)
        let result = topic.currentWeight(at: twoHalfLivesLater, halfLifeDays: 30)
        #expect(abs(result - 0.25) < 0.0001)
    }

    @Test("currentWeight returns stored weight for past dates (no negative decay)")
    func currentWeightForPastDate() {
        let topic = makeTopic(weight: 2.0)
        let earlier = Self.referenceDate.addingTimeInterval(-86400)
        #expect(topic.currentWeight(at: earlier) == 2.0)
    }

    @Test("currentWeight returns stored weight for non-positive half-life")
    func currentWeightForZeroHalfLife() {
        let topic = makeTopic(weight: 3.0)
        let later = Self.referenceDate.addingTimeInterval(86400)
        #expect(topic.currentWeight(at: later, halfLifeDays: 0) == 3.0)
    }

    @Test("Codable round-trip preserves all fields")
    func codableRoundTrip() throws {
        let topic = InterestTopic(
            topicID: "ai",
            displayName: "AI",
            weight: 2.5,
            category: NewsCategory.technology.rawValue,
            lastReinforcedAt: Self.referenceDate,
            createdAt: Self.referenceDate.addingTimeInterval(-3600),
            source: .extracted,
        )
        let data = try JSONEncoder().encode(topic)
        let decoded = try JSONDecoder().decode(InterestTopic.self, from: data)
        #expect(decoded == topic)
    }

    @Test("id property returns topicID")
    func idReturnsTopicID() {
        let topic = makeTopic()
        #expect(topic.id == topic.topicID)
    }
}
