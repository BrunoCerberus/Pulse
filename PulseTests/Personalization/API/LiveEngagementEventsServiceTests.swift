import Foundation
@testable import Pulse
import Testing

@Suite("LiveEngagementEventsService Tests")
@MainActor
struct LiveEngagementEventsServiceTests {
    private let sut: LiveEngagementEventsService

    private static let baseDate = Date(timeIntervalSince1970: 1_700_000_000)

    init() {
        sut = LiveEngagementEventsService(inMemory: true)
    }

    private func makeEvent(
        articleID: String = "article-1",
        kind: EngagementEvent.Kind = .read30s,
        offset: TimeInterval = 0,
    ) -> EngagementEvent {
        EngagementEvent(
            id: UUID(),
            articleID: articleID,
            articleTitle: "Title",
            articleSummary: "Summary",
            categoryRaw: NewsCategory.technology.rawValue,
            kind: kind,
            weight: nil,
            occurredAt: Self.baseDate.addingTimeInterval(offset),
        )
    }

    @Test("Recording an event makes it visible to pendingEvents")
    func recordingMakesEventPending() async throws {
        let event = makeEvent()
        await sut.record(event)

        let pending = try await sut.pendingEvents(limit: 10)
        #expect(pending.count == 1)
        #expect(pending.first == event)
    }

    @Test("Recording the same event ID twice produces a single row")
    func recordingSameIdIsIdempotent() async throws {
        let event = makeEvent()
        await sut.record(event)
        await sut.record(event)

        let pending = try await sut.pendingEvents(limit: 10)
        #expect(pending.count == 1)
    }

    @Test("pendingEvents returns events ordered oldest-first")
    func pendingEventsOldestFirst() async throws {
        let oldest = makeEvent(articleID: "a", offset: 0)
        let middle = makeEvent(articleID: "b", offset: 60)
        let newest = makeEvent(articleID: "c", offset: 120)

        // Insert in non-monotonic order to confirm sort, not insertion order.
        await sut.record(middle)
        await sut.record(newest)
        await sut.record(oldest)

        let pending = try await sut.pendingEvents(limit: 10)
        #expect(pending.map(\.articleID) == ["a", "b", "c"])
    }

    @Test("pendingEvents respects the limit parameter")
    func pendingEventsRespectsLimit() async throws {
        for index in 0 ..< 5 {
            await sut.record(makeEvent(articleID: "a-\(index)", offset: TimeInterval(index)))
        }
        let pending = try await sut.pendingEvents(limit: 3)
        #expect(pending.count == 3)
    }

    @Test("markProcessed removes the specified events")
    func markProcessedRemovesEvents() async throws {
        let keep = makeEvent(articleID: "keep", offset: 0)
        let drop = makeEvent(articleID: "drop", offset: 60)
        await sut.record(keep)
        await sut.record(drop)

        try await sut.markProcessed([drop.id])

        let remaining = try await sut.pendingEvents(limit: 10)
        #expect(remaining.count == 1)
        #expect(remaining.first?.articleID == "keep")
    }

    @Test("markProcessed with unknown IDs does not throw")
    func markProcessedUnknownIDsIsNoop() async throws {
        try await sut.markProcessed([UUID()])
        let remaining = try await sut.pendingEvents(limit: 10)
        #expect(remaining.isEmpty)
    }

    @Test("markProcessed with empty array is a no-op")
    func markProcessedEmptyArrayIsNoop() async throws {
        let event = makeEvent()
        await sut.record(event)

        try await sut.markProcessed([])

        let remaining = try await sut.pendingEvents(limit: 10)
        #expect(remaining.count == 1)
    }

    @Test("clearAll removes every pending event")
    func clearAllRemovesEverything() async throws {
        for index in 0 ..< 3 {
            await sut.record(makeEvent(articleID: "a-\(index)", offset: TimeInterval(index)))
        }
        try await sut.clearAll()
        let remaining = try await sut.pendingEvents(limit: 10)
        #expect(remaining.isEmpty)
    }
}
