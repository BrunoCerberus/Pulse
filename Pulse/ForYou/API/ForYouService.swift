import Foundation

/// Protocol for the For You feed service — composes the user's interest
/// profile with a pool of candidate articles to produce a ranked list.
///
/// The service intentionally does **not** fetch its own pool. Callers (the
/// `ForYouDomainInteractor`) supply already-loaded articles from the cache
/// layer so we don't double-fetch or fight `CachingNewsService` for the
/// same network slot.
///
/// ## v1 scoring
///
/// We score by article *category* against the profile. The Phase 3 LLM
/// extraction enriches the profile with per-article tags over time, but at
/// scoring time the candidate article's own tags aren't available without
/// another LLM pass — so the v1 surface is effectively "rank by followed-
/// category strength," cold-start-safe via the onboarding seed.
protocol ForYouService {
    /// Returns the top-`topN` articles by personalization score, with
    /// zero-score articles filtered out (so the For You section stays
    /// hidden when there's no signal yet).
    func scoredArticles(from pool: [Article], topN: Int) async throws -> [ScoredArticle]

    /// Non-LLM static explanation. Phase 5 may upgrade this to an
    /// LLM-generated rationale (Premium gate). For now: `"Matched: A, B, C"`.
    func explanation(for matchedTopics: [String]) -> String
}
