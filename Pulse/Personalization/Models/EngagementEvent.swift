import Foundation

/// Captures a user-engagement signal on an article — read for ≥30 s, bookmarked,
/// shared, etc. Events accumulate locally on-device and are later drained by
/// the topic-extraction pipeline (Phase 3) to update the interest profile.
///
/// All article fields are captured at event time so downstream extraction does
/// not need to refetch — the article may have rolled off the feed by then.
struct EngagementEvent: Equatable, Codable, Identifiable {
    /// Engagement signal kind. Weights (positive or negative) accumulate into
    /// per-topic interest scores in `LiveInterestProfileService`.
    enum Kind: String, Codable, CaseIterable {
        case read30s
        case completedRead
        case bookmarked
        case shared
        case dismissed
    }

    let id: UUID
    let articleID: String
    let articleTitle: String
    let articleSummary: String?
    /// Raw value of `NewsCategory` (or `nil`). Stored as `String` so the model is
    /// trivially `Codable` and SwiftData-friendly.
    let categoryRaw: String?
    let kind: Kind
    let weight: Double
    let occurredAt: Date

    init(
        id: UUID = UUID(),
        articleID: String,
        articleTitle: String,
        articleSummary: String?,
        categoryRaw: String?,
        kind: Kind,
        weight: Double? = nil,
        occurredAt: Date = .now
    ) {
        self.id = id
        self.articleID = articleID
        self.articleTitle = articleTitle
        self.articleSummary = articleSummary
        self.categoryRaw = categoryRaw
        self.kind = kind
        self.weight = weight ?? Self.defaultWeight(for: kind)
        self.occurredAt = occurredAt
    }

    /// Default weight per signal kind. Higher absolute values are stronger
    /// signals; negative values nudge interest *away* from the topic.
    static func defaultWeight(for kind: Kind) -> Double {
        switch kind {
        case .read30s: 1.0
        case .completedRead: 2.0
        case .bookmarked: 3.0
        case .shared: 4.0
        case .dismissed: -1.0
        }
    }
}

extension EngagementEvent {
    /// Captures an engagement signal for `article`, snapshotting title /
    /// description / category at event time.
    init(from article: Article, kind: Kind, weight: Double? = nil, occurredAt: Date = .now) {
        self.init(
            id: UUID(),
            articleID: article.id,
            articleTitle: article.title,
            articleSummary: article.description,
            categoryRaw: article.category?.rawValue,
            kind: kind,
            weight: weight,
            occurredAt: occurredAt
        )
    }
}
