import EntropyCore
import Foundation
import SwiftData

/// Live implementation of `EngagementEventsService` backed by SwiftData.
///
/// Owns its **own** `ModelContainer` separate from `LiveStorageService` —
/// `PendingEngagementEvent` is intentionally not CloudKit-mirrored. Each
/// device collects its own engagement signals, so there's no value (and a
/// privacy cost) in syncing them.
///
/// Failure to create the underlying container is non-fatal: the service
/// silently no-ops, matching the project's "personalization is opportunistic"
/// posture (telemetry breakage shouldn't kill the app).
final class LiveEngagementEventsService: EngagementEventsService {
    private let modelContainer: ModelContainer?

    init(inMemory: Bool = false) {
        do {
            let schema = Schema([PendingEngagementEvent.self])
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: inMemory,
            )
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            Logger.shared.service(
                "Failed to create EngagementEvents container: \(error)",
                level: .warning,
            )
            modelContainer = nil
        }
    }

    @MainActor
    func record(_ event: EngagementEvent) async {
        guard let container = modelContainer else { return }
        let context = container.mainContext

        let eventID = event.id.uuidString
        let descriptor = FetchDescriptor<PendingEngagementEvent>(
            predicate: #Predicate { $0.eventID == eventID },
        )
        if (try? context.fetch(descriptor).first) != nil {
            return
        }

        context.insert(PendingEngagementEvent(from: event))
        do {
            try context.save()
        } catch {
            Logger.shared.service(
                "EngagementEvents save failed: \(error)",
                level: .debug,
            )
        }
    }

    @MainActor
    func pendingEvents(limit: Int) async throws -> [EngagementEvent] {
        guard let container = modelContainer else { return [] }
        let context = container.mainContext

        var descriptor = FetchDescriptor<PendingEngagementEvent>(
            sortBy: [SortDescriptor(\.occurredAt, order: .forward)],
        )
        descriptor.fetchLimit = limit

        let rows = try context.fetch(descriptor)
        return rows.compactMap { $0.toEvent() }
    }

    @MainActor
    func markProcessed(_ eventIDs: [UUID]) async throws {
        guard let container = modelContainer, !eventIDs.isEmpty else { return }
        let context = container.mainContext

        let ids = Set(eventIDs.map(\.uuidString))
        let descriptor = FetchDescriptor<PendingEngagementEvent>(
            predicate: #Predicate { ids.contains($0.eventID) },
        )
        let rows = try context.fetch(descriptor)
        for row in rows {
            context.delete(row)
        }
        try context.save()
    }

    @MainActor
    func clearAll() async throws {
        guard let container = modelContainer else { return }
        let context = container.mainContext
        try context.delete(model: PendingEngagementEvent.self)
        try context.save()
    }
}
