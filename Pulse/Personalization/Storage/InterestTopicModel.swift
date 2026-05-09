import Foundation
import SwiftData

/// SwiftData model for persisting an interest-profile row.
///
/// Every property has a default value so the model is compatible with
/// CloudKit sync via `NSPersistentCloudKitContainer`. Uniqueness on
/// `topicID` is enforced at the service layer (`LiveInterestProfileService`
/// fetches by `topicID` before inserting), matching the convention used by
/// `BookmarkedArticle` / `ReadArticle`.
@Model
final class InterestTopicModel {
    /// Stable identifier, lowercase kebab-case. Conceptually unique across
    /// all rows for a user; the service layer enforces this on upsert.
    var topicID: String = ""
    /// Display name shown in Settings.
    var displayName: String = ""
    /// Stored weight as of `lastReinforcedAt`.
    var weight: Double = 0.0
    /// Optional `NewsCategory.rawValue` for canonical seed topics.
    var category: String?
    /// Timestamp of the most recent engagement that touched this topic.
    var lastReinforcedAt: Date = Date()
    var createdAt: Date = Date()
    /// `InterestTopic.Source.rawValue`.
    ///
    /// Defaults to `.extracted` because that's the most common provenance
    /// by volume (LLM-extracted tags accumulate per article read), so a row
    /// that loses its `sourceRaw` value across a CloudKit migration or
    /// schema bump is statistically most likely to have *been* an extracted
    /// row. The trade-off: a `.seed` row that loses `sourceRaw` would mis-
    /// label as `.extracted` in the Settings list. We accept that risk in
    /// favour of "label something sensible" over "leave it nil and surface
    /// 'Unknown source' to users." If the schema ever evolves to add a new
    /// `Source` case, give it precedence over this default.
    var sourceRaw: String = InterestTopic.Source.extracted.rawValue

    init(from topic: InterestTopic) {
        topicID = topic.topicID
        displayName = topic.displayName
        weight = topic.weight
        category = topic.category
        lastReinforcedAt = topic.lastReinforcedAt
        createdAt = topic.createdAt
        sourceRaw = topic.source.rawValue
    }

    /// Returns the persisted row as a value-typed `InterestTopic`, or `nil`
    /// if `sourceRaw` is corrupted across schema versions.
    func toTopic() -> InterestTopic? {
        guard let source = InterestTopic.Source(rawValue: sourceRaw) else {
            return nil
        }
        return InterestTopic(
            topicID: topicID,
            displayName: displayName,
            weight: weight,
            category: category,
            lastReinforcedAt: lastReinforcedAt,
            createdAt: createdAt,
            source: source
        )
    }
}
