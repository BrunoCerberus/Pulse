import Foundation

/// In-memory mock of `ForYouService` for tests / SwiftUI previews.
final class MockForYouService: ForYouService, @unchecked Sendable {
    var scoredArticlesResult: Result<[ScoredArticle], Error> = .success([])
    var explanationOverride: String?
    private(set) var lastPool: [Article] = []
    private(set) var lastTopN: Int = 0

    func scoredArticles(from pool: [Article], topN: Int) async throws -> [ScoredArticle] {
        lastPool = pool
        lastTopN = topN
        return try scoredArticlesResult.get()
    }

    func explanation(for matchedTopics: [String]) -> String {
        if let explanationOverride { return explanationOverride }
        return matchedTopics.joined(separator: ", ")
    }
}
