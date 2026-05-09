import Foundation
@testable import Pulse
import Testing

@Suite("MockEngagementEventsService Tests")
struct MockEngagementEventsServiceTests {
    private static let baseDate = Date(timeIntervalSince1970: 1_700_000_000)

    private func makeEvent(
        articleID: String = "a",
        offset: TimeInterval = 0
    ) -> EngagementEvent {
        EngagementEvent(
            id: UUID(),
            articleID: articleID,
            articleTitle: "Title",
            articleSummary: nil,
            categoryRaw: nil,
            kind: .read30s,
            weight: nil,
            occurredAt: Self.baseDate.addingTimeInterval(offset)
        )
    }

    @Test("Recording captures events into recordedEvents")
    func recordingCaptures() async {
        let sut = MockEngagementEventsService()
        let event = makeEvent()
        await sut.record(event)
        #expect(sut.recordedEvents == [event])
    }

    @Test("pendingEvents returns events ordered oldest-first up to limit")
    func pendingEventsOrderingAndLimit() async throws {
        let sut = MockEngagementEventsService()
        await sut.record(makeEvent(articleID: "newer", offset: 60))
        await sut.record(makeEvent(articleID: "older", offset: 0))

        let result = try await sut.pendingEvents(limit: 10)
        #expect(result.map(\.articleID) == ["older", "newer"])
    }

    @Test("pendingEventsError surfaces injected errors")
    func pendingEventsSurfacesError() async {
        struct InjectedError: Error {}
        let sut = MockEngagementEventsService()
        sut.pendingEventsError = InjectedError()

        await #expect(throws: InjectedError.self) {
            _ = try await sut.pendingEvents(limit: 10)
        }
    }

    @Test("markProcessed removes specified events")
    func markProcessedRemoves() async throws {
        let sut = MockEngagementEventsService()
        let keep = makeEvent(articleID: "keep")
        let drop = makeEvent(articleID: "drop", offset: 60)
        await sut.record(keep)
        await sut.record(drop)

        try await sut.markProcessed([drop.id])

        #expect(sut.recordedEvents.map(\.articleID) == ["keep"])
    }

    @Test("clearAll empties recordedEvents")
    func clearAllEmpties() async throws {
        let sut = MockEngagementEventsService()
        await sut.record(makeEvent())
        try await sut.clearAll()
        #expect(sut.recordedEvents.isEmpty)
    }
}
