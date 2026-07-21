import Foundation

/// Pure scoring logic for the For You feed — no I/O, no dependencies, no
/// actor isolation. Lives in `Models/` because it's a value-typed algorithm,
/// not a service.
///
/// ## Algorithm: weighted Jaccard with category fallback
///
/// 1. Build the set of "article tags" — either the LLM-extracted tags
///    (Phase 3 output) if present, or the article's `category.rawValue`
///    as a single-element fallback (so cold-start users still get
///    *some* signal).
///
/// 2. Build the per-topic weights from the profile, applying time-decay
///    via `InterestTopic.currentWeight(at:halfLifeDays:)`.
///
/// 3. Score = Σ(profile.weight where topicID ∈ articleTags) /
///            max(1, Σ profile.weight)  — clamped to `[0, 1]`.
///
/// We deliberately avoid embedding similarity for v1: SwiftLlama doesn't
/// expose embeddings, and weighted-Jaccard on 3–5 article tags vs a
/// 30–50-row profile converges cleanly and is **explainable** ("matched:
/// AI, climate-change") which the "Why this?" affordance leans on.
enum ArticleScorer {
    /// Scores `article` against `profile` using the article's extracted
    /// tags (or its category as a fallback).
    ///
    /// - Parameters:
    ///   - article: The candidate article.
    ///   - articleTags: Optional pre-extracted tags. If `nil` or empty,
    ///     falls back to `[article.category?.rawValue].compactMap { $0 }`.
    ///   - profile: The user's interest topics.
    ///   - now: Reference date for decay (override in tests).
    ///   - halfLifeDays: Half-life for time-decay of profile weights.
    /// - Returns: A `ScoredArticle` with score clamped to `[0, 1]`.
    static func score(
        article: Article,
        articleTags: [String]? = nil,
        profile: [InterestTopic],
        now: Date = .now,
        halfLifeDays: Double = 30.0,
    ) -> ScoredArticle {
        let tags: Set<String> = {
            if let articleTags, !articleTags.isEmpty {
                return Set(articleTags.map { $0.lowercased() })
            }
            // Cold-start fallback — without LLM extraction, we still match
            // by canonical category so seeded onboarding rows score above 0.
            if let categoryRaw = article.category?.rawValue {
                return [categoryRaw.lowercased()]
            }
            return []
        }()

        guard !tags.isEmpty, !profile.isEmpty else {
            return ScoredArticle(article: article, score: 0, matchedTopics: [])
        }

        var matchedWeight = 0.0
        var matchedTopics: [String] = []
        var totalWeight = 0.0

        for topic in profile {
            let weight = max(0, topic.currentWeight(at: now, halfLifeDays: halfLifeDays))
            totalWeight += weight
            if tags.contains(topic.topicID.lowercased()) {
                matchedWeight += weight
                matchedTopics.append(topic.topicID)
            }
        }

        // Clamp into [0, 1]. `totalWeight == 0` means the profile decayed
        // entirely — score 0, which keeps the For You section hidden until
        // signals refresh.
        let normalised = totalWeight > 0 ? min(1, max(0, matchedWeight / totalWeight)) : 0
        return ScoredArticle(article: article, score: normalised, matchedTopics: matchedTopics)
    }
}
