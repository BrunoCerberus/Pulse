import Foundation

/// Live implementation of `ForYouService`.
///
/// Composes `InterestProfileService` (data) with `ArticleScorer` (algorithm)
/// — both pure-ish dependencies, so this service is largely a coordination
/// layer. The `StorageService` dependency is used solely to filter out
/// already-engaged articles so the carousel doesn't surface the same items
/// the user just read or bookmarked (which would render adjacent to each
/// other on the Home screen).
final class LiveForYouService: ForYouService {
    private let profileService: InterestProfileService
    private let storageService: StorageService?

    init(profileService: InterestProfileService, storageService: StorageService? = nil) {
        self.profileService = profileService
        self.storageService = storageService
    }

    func scoredArticles(from pool: [Article], topN: Int) async throws -> [ScoredArticle] {
        guard topN > 0, !pool.isEmpty else { return [] }
        let profile = try await profileService.fetchProfile()
        guard !profile.isEmpty else { return [] }

        // Exclude articles the user has already engaged with — those belong
        // in `Recently Read` / `Bookmarks`, not in a "what's new for you"
        // carousel. Best-effort: if either fetch fails we just don't filter.
        var excludedIDs = Set<String>()
        if let storageService {
            if let read = try? await storageService.fetchReadArticleIDs() {
                excludedIDs.formUnion(read)
            }
            if let bookmarks = try? await storageService.fetchBookmarkedArticles() {
                excludedIDs.formUnion(bookmarks.map(\.id))
            }
        }
        let candidates = excludedIDs.isEmpty
            ? pool
            : pool.filter { !excludedIDs.contains($0.id) }

        let scored = candidates.map { article in
            ArticleScorer.score(article: article, articleTags: nil, profile: profile)
        }
        return Array(
            scored
                .filter { $0.score > 0 }
                .sorted { $0.score > $1.score }
                .prefix(topN)
        )
    }

    func explanation(for matchedTopics: [String]) -> String {
        guard !matchedTopics.isEmpty else { return "" }
        return matchedTopics
            .prefix(3)
            .map { TopicExtractionPromptBuilder.displayName(for: $0) }
            .joined(separator: ", ")
    }
}
