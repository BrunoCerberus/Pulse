import Foundation

/// Pure, synchronous filtering step that turns a raw article pool into the
/// candidate set for a Smart Briefing run.
///
/// Read/bookmarked-article exclusion already happens inside
/// `ForYouService.scoredArticles` — this builder only owns the
/// Smart-Briefing-specific concerns (the "since last served" scope cutoff
/// and served-ID de-duplication), so it has no service dependency and can
/// be unit-tested without mocks.
enum SmartBriefingQueueBuilder {
    static func filterPool(
        _ pool: [Article],
        scope: SmartBriefingScope,
        lastServedAt: Date?,
        servedArticleIDs: Set<String>
    ) -> [Article] {
        var candidates = pool
        if scope == .unreadSinceLastBriefing, let lastServedAt {
            candidates = candidates.filter { $0.publishedAt > lastServedAt }
        }
        if !servedArticleIDs.isEmpty {
            candidates = candidates.filter { !servedArticleIDs.contains($0.id) }
        }
        return candidates
    }
}
