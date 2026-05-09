import Foundation

/// Protocol defining the queue interface for `EngagementEvent`s awaiting
/// topic extraction.
///
/// Events are produced by feature interactors (e.g. `ArticleDetailDomainInteractor`)
/// and consumed by the topic-extraction drainer (Phase 3). The queue is
/// strictly device-local — we never sync engagement signals to CloudKit.
///
/// ## Thread Safety
/// All operations are `async`. Implementations may be `@MainActor`-bound;
/// callers should wrap the service in `UncheckedSendableBox` when crossing
/// `Task` boundaries (matches the `StorageService` access pattern).
protocol EngagementEventsService {
    /// Persists `event` to the local queue. Failures are logged but never
    /// surfaced — engagement capture is best-effort and must never disrupt
    /// the article-reading flow.
    func record(_ event: EngagementEvent) async

    /// Fetches up to `limit` pending events ordered by `occurredAt` ascending
    /// (oldest first), so the drainer processes signals in the order they
    /// happened.
    func pendingEvents(limit: Int) async throws -> [EngagementEvent]

    /// Removes events from the queue after their topics have been extracted
    /// and applied to the interest profile. Idempotent — IDs that no longer
    /// exist are silently ignored.
    func markProcessed(_ eventIDs: [UUID]) async throws

    /// Wipes all pending events. Called from `clearAllUserData` on sign-out
    /// or account deletion.
    func clearAll() async throws
}
