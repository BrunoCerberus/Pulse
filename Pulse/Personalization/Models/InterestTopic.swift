import Foundation

/// Value type representing a single learned interest topic in the user's
/// personalization profile. Stored as `InterestTopicModel` (SwiftData,
/// CloudKit-synced) and surfaced as this snapshot at service boundaries.
///
/// Topics accumulate `weight` over time as the user engages with related
/// articles. Weight is *not* mutated on a schedule — instead, the stored
/// weight reflects engagement up to `lastReinforcedAt`, and effective
/// "current" weight is computed on demand via `currentWeight(at:halfLifeDays:)`.
/// This avoids the idempotency footguns of periodic batch decay.
struct InterestTopic: Equatable, Codable, Identifiable {
    /// Provenance of an interest row. Used for explainability ("why this?")
    /// and for letting the user audit / clean their profile.
    enum Source: String, Codable, CaseIterable {
        /// Picked during onboarding from `NewsCategory`.
        case seed
        /// Produced by on-device LLM topic extraction (Phase 3).
        case extracted
        /// Added by the user via Settings (Phase 5).
        case manual
    }

    /// Stable identifier. Convention: lowercase kebab-case
    /// (e.g. `"artificial-intelligence"`).
    let topicID: String
    /// Human-readable name for display in Settings (`"Artificial Intelligence"`).
    let displayName: String
    /// Cumulative weight as of `lastReinforcedAt`. Use `currentWeight(at:)`
    /// for time-decayed comparisons.
    let weight: Double
    /// Optional `NewsCategory.rawValue` if this row corresponds to a canonical
    /// category (for seed rows; nil for LLM-extracted topics).
    let category: String?
    let lastReinforcedAt: Date
    let createdAt: Date
    let source: Source

    var id: String {
        topicID
    }

    /// Time-decayed weight at `date`, halving every `halfLifeDays`.
    /// Default half-life of 30 days strikes a reasonable balance between
    /// "stale interests fade" and "consistent interests stay surfaced".
    func currentWeight(at date: Date = .now, halfLifeDays: Double = 30.0) -> Double {
        let secondsSince = date.timeIntervalSince(lastReinforcedAt)
        guard secondsSince > 0, halfLifeDays > 0 else { return weight }
        let daysSince = secondsSince / 86400
        let decay = exp(-Foundation.log(2) * daysSince / halfLifeDays)
        return weight * decay
    }
}
