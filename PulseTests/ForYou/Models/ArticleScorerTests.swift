import Foundation
@testable import Pulse
import Testing

@Suite("ArticleScorer Tests")
struct ArticleScorerTests {
    private static let baseDate = Date(timeIntervalSince1970: 1_700_000_000)

    private func makeArticle(category: NewsCategory? = .technology) -> Article {
        Article(
            id: "a1",
            title: "Test",
            description: nil,
            content: nil,
            author: nil,
            source: ArticleSource(id: "s", name: "Source"),
            url: "https://example.com",
            imageURL: nil,
            publishedAt: Self.baseDate,
            category: category
        )
    }

    private func makeTopic(
        topicID: String,
        weight: Double,
        lastReinforcedAt: Date = Self.baseDate
    ) -> InterestTopic {
        InterestTopic(
            topicID: topicID,
            displayName: topicID,
            weight: weight,
            category: nil,
            lastReinforcedAt: lastReinforcedAt,
            createdAt: lastReinforcedAt,
            source: .extracted
        )
    }

    @Test("Empty profile yields score 0")
    func emptyProfileYieldsZero() {
        let result = ArticleScorer.score(
            article: makeArticle(),
            articleTags: ["technology"],
            profile: []
        )
        #expect(result.score == 0)
        #expect(result.matchedTopics.isEmpty)
    }

    @Test("Article with no tags and no category yields score 0")
    func noTagsAndNoCategoryYieldsZero() {
        let article = makeArticle(category: nil)
        let profile = [makeTopic(topicID: "technology", weight: 1)]
        let result = ArticleScorer.score(article: article, articleTags: nil, profile: profile)
        #expect(result.score == 0)
    }

    @Test("Falls back to category when articleTags is nil")
    func categoryFallbackWhenTagsNil() {
        let profile = [makeTopic(topicID: "technology", weight: 1)]
        let result = ArticleScorer.score(article: makeArticle(), articleTags: nil, profile: profile)
        #expect(result.score == 1.0)
        #expect(result.matchedTopics == ["technology"])
    }

    @Test("Falls back to category when articleTags is empty")
    func categoryFallbackWhenTagsEmpty() {
        let profile = [makeTopic(topicID: "technology", weight: 1)]
        let result = ArticleScorer.score(article: makeArticle(), articleTags: [], profile: profile)
        #expect(result.score == 1.0)
    }

    @Test("Perfect overlap yields score 1.0")
    func perfectOverlap() {
        let profile = [
            makeTopic(topicID: "ai", weight: 2),
            makeTopic(topicID: "climate", weight: 3),
        ]
        let result = ArticleScorer.score(
            article: makeArticle(),
            articleTags: ["ai", "climate"],
            profile: profile
        )
        #expect(abs(result.score - 1.0) < 0.0001)
        #expect(Set(result.matchedTopics) == ["ai", "climate"])
    }

    @Test("Partial overlap yields proportional score")
    func partialOverlap() {
        let profile = [
            makeTopic(topicID: "ai", weight: 1),
            makeTopic(topicID: "sports", weight: 1),
            makeTopic(topicID: "climate", weight: 1),
        ]
        // Article tags hit 2 of 3 profile topics, equal weights → 2/3
        let result = ArticleScorer.score(
            article: makeArticle(),
            articleTags: ["ai", "climate"],
            profile: profile
        )
        #expect(abs(result.score - (2.0 / 3.0)) < 0.0001)
        #expect(Set(result.matchedTopics) == ["ai", "climate"])
    }

    @Test("Higher-weight topics dominate the score")
    func weightDominates() {
        let profile = [
            makeTopic(topicID: "ai", weight: 9),
            makeTopic(topicID: "sports", weight: 1),
        ]
        // Match only the high-weight topic → 9 / (9+1) = 0.9
        let result = ArticleScorer.score(
            article: makeArticle(),
            articleTags: ["ai"],
            profile: profile
        )
        #expect(abs(result.score - 0.9) < 0.0001)
    }

    @Test("Tag matching is case-insensitive")
    func caseInsensitiveMatch() {
        let profile = [makeTopic(topicID: "ai", weight: 1)]
        let result = ArticleScorer.score(
            article: makeArticle(),
            articleTags: ["AI"],
            profile: profile
        )
        #expect(result.score == 1.0)
    }

    @Test("Decayed weights reduce contribution proportionally")
    func decayReducesContribution() {
        let oneHalfLifeAgo = Self.baseDate.addingTimeInterval(-30 * 86400)
        let profile = [
            // Half-decayed (weight 1.0 stored, but effective at the test
            // date is 0.5 with halfLifeDays = 30).
            makeTopic(topicID: "ai", weight: 1.0, lastReinforcedAt: oneHalfLifeAgo),
            // Fresh weight, full contribution.
            makeTopic(topicID: "sports", weight: 0.5),
        ]
        // matchedWeight = 0.5 (decayed AI); totalWeight = 0.5 + 0.5 = 1.0 → 0.5
        let result = ArticleScorer.score(
            article: makeArticle(),
            articleTags: ["ai"],
            profile: profile,
            now: Self.baseDate,
            halfLifeDays: 30
        )
        #expect(abs(result.score - 0.5) < 0.01)
    }

    @Test("Score is clamped to [0, 1]")
    func scoreClamped() {
        let profile = [makeTopic(topicID: "ai", weight: 100)]
        let result = ArticleScorer.score(
            article: makeArticle(),
            articleTags: ["ai"],
            profile: profile
        )
        #expect(result.score >= 0)
        #expect(result.score <= 1)
    }
}
