import Foundation

/// In-memory mock of `EngagementEventsService` for unit / UI / preview tests.
///
/// Exposes `recordedEvents` for direct assertion in tests, plus error-injection
/// hooks (`pendingEventsError`, `markProcessedError`) matching the convention
/// used by `MockStorageService`.
final class MockEngagementEventsService: EngagementEventsService, @unchecked Sendable {
    var recordedEvents: [EngagementEvent] = []
    var pendingEventsError: Error?
    var markProcessedError: Error?

    func record(_ event: EngagementEvent) async {
        recordedEvents.append(event)
    }

    func pendingEvents(limit: Int) async throws -> [EngagementEvent] {
        if let pendingEventsError {
            throw pendingEventsError
        }
        let sorted = recordedEvents.sorted { $0.occurredAt < $1.occurredAt }
        return Array(sorted.prefix(limit))
    }

    func markProcessed(_ eventIDs: [UUID]) async throws {
        if let markProcessedError {
            throw markProcessedError
        }
        let ids = Set(eventIDs)
        recordedEvents.removeAll { ids.contains($0.id) }
    }

    func clearAll() async throws {
        recordedEvents = []
    }
}
