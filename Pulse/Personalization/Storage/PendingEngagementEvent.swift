import Foundation
import SwiftData

/// SwiftData model for queued engagement events awaiting topic extraction.
///
/// Every property has a default value (CloudKit-compat convention) — even
/// though this model is **not** CloudKit-mirrored. Events are ephemeral
/// signals; we drain them locally and never sync, so each device collects its
/// own engagement history.
///
/// Uniqueness is enforced at the service layer (`LiveEngagementEventsService`
/// fetches by `eventID` before inserting) rather than via `@Attribute(.unique)`,
/// matching the project convention used by `BookmarkedArticle` / `ReadArticle`.
@Model
final class PendingEngagementEvent {
    /// UUID string of the originating `EngagementEvent`.
    var eventID: String = ""
    var articleID: String = ""
    var articleTitle: String = ""
    var articleSummary: String?
    var categoryRaw: String?
    /// Raw value of `EngagementEvent.Kind`.
    var kindRaw: String = ""
    var weight: Double = 0.0
    var occurredAt: Date = Date()

    init(from event: EngagementEvent) {
        eventID = event.id.uuidString
        articleID = event.articleID
        articleTitle = event.articleTitle
        articleSummary = event.articleSummary
        categoryRaw = event.categoryRaw
        kindRaw = event.kind.rawValue
        weight = event.weight
        occurredAt = event.occurredAt
    }

    /// Returns the persisted row as a value-typed `EngagementEvent`, or `nil`
    /// if `kindRaw` / `eventID` is corrupt (e.g. schema drift across versions).
    func toEvent() -> EngagementEvent? {
        guard let kind = EngagementEvent.Kind(rawValue: kindRaw),
              let uuid = UUID(uuidString: eventID)
        else {
            return nil
        }
        return EngagementEvent(
            id: uuid,
            articleID: articleID,
            articleTitle: articleTitle,
            articleSummary: articleSummary,
            categoryRaw: categoryRaw,
            kind: kind,
            weight: weight,
            occurredAt: occurredAt
        )
    }
}
