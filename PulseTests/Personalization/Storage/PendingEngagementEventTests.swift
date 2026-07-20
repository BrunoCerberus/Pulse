import Foundation
@testable import Pulse
import Testing

@Suite("PendingEngagementEvent Tests")
struct PendingEngagementEventTests {
    private static let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)

    private func makeEvent(kind: EngagementEvent.Kind = .read30s) -> EngagementEvent {
        EngagementEvent(
            id: UUID(),
            articleID: "article-1",
            articleTitle: "Headline",
            articleSummary: "Summary",
            categoryRaw: NewsCategory.science.rawValue,
            kind: kind,
            weight: 2.5,
            occurredAt: Self.referenceDate,
        )
    }

    @Test("Init from event preserves every field")
    func initPreservesAllFields() {
        let event = makeEvent(kind: .bookmarked)
        let row = PendingEngagementEvent(from: event)

        #expect(row.eventID == event.id.uuidString)
        #expect(row.articleID == event.articleID)
        #expect(row.articleTitle == event.articleTitle)
        #expect(row.articleSummary == event.articleSummary)
        #expect(row.categoryRaw == event.categoryRaw)
        #expect(row.kindRaw == event.kind.rawValue)
        #expect(row.weight == event.weight)
        #expect(row.occurredAt == event.occurredAt)
    }

    @Test("Round-trip via toEvent restores the original value")
    func roundTripRestoresEvent() throws {
        let event = makeEvent(kind: .shared)
        let row = PendingEngagementEvent(from: event)
        let restored = try #require(row.toEvent())
        #expect(restored == event)
    }

    @Test("toEvent returns nil when kindRaw is corrupted")
    func toEventNilOnCorruptedKind() {
        let row = PendingEngagementEvent(from: makeEvent())
        row.kindRaw = "not-a-valid-kind"
        #expect(row.toEvent() == nil)
    }

    @Test("toEvent returns nil when eventID is not a UUID")
    func toEventNilOnInvalidUUID() {
        let row = PendingEngagementEvent(from: makeEvent())
        row.eventID = "not-a-uuid"
        #expect(row.toEvent() == nil)
    }
}
