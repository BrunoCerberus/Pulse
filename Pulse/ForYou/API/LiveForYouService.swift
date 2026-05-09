import Foundation

/// Live implementation of `ForYouService`.
///
/// Composes `InterestProfileService` (data) with `ArticleScorer` (algorithm)
/// — both pure-ish dependencies, so this service is largely a coordination
/// layer. No I/O of its own beyond the profile fetch.
final class LiveForYouService: ForYouService {
    private let profileService: InterestProfileService

    init(profileService: InterestProfileService) {
        self.profileService = profileService
    }

    func scoredArticles(from pool: [Article], topN: Int) async throws -> [ScoredArticle] {
        guard topN > 0, !pool.isEmpty else { return [] }
        let profile = try await profileService.fetchProfile()
        guard !profile.isEmpty else { return [] }

        let scored = pool.map { article in
            ArticleScorer.score(article: article, articleTags: nil, profile: profile)
        }
        return scored
            .filter { $0.score > 0 }
            .sorted { $0.score > $1.score }
            .prefix(topN)
            .map { $0 }
    }

    func explanation(for matchedTopics: [String]) -> String {
        guard !matchedTopics.isEmpty else { return "" }
        return matchedTopics
            .prefix(3)
            .map { TopicExtractionPromptBuilder.displayName(for: $0) }
            .joined(separator: ", ")
    }
}
