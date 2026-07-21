import Foundation
@testable import Pulse
import Testing

@Suite("LiveForYouService Tests")
@MainActor
struct LiveForYouServiceTests {
    private static let baseDate = Date(timeIntervalSince1970: 1_700_000_000)

    private func makeArticle(id: String, category: NewsCategory) -> Article {
        Article(
            id: id,
            title: "Article \(id)",
            description: nil,
            content: nil,
            author: nil,
            source: ArticleSource(id: "src", name: "Source"),
            url: "https://example.com/\(id)",
            imageURL: nil,
            publishedAt: Self.baseDate,
            category: category,
        )
    }

    @Test("Returns empty when topN is 0 or pool is empty")
    func emptyResults() async throws {
        let profileService = MockInterestProfileService()
        let sut = LiveForYouService(profileService: profileService)

        let pool = [makeArticle(id: "a", category: .technology)]
        let zeroTop = try await sut.scoredArticles(from: pool, topN: 0)
        let emptyPool = try await sut.scoredArticles(from: [], topN: 5)

        #expect(zeroTop.isEmpty)
        #expect(emptyPool.isEmpty)
    }

    @Test("Returns empty when profile is empty")
    func emptyProfile() async throws {
        let profileService = MockInterestProfileService()
        let sut = LiveForYouService(profileService: profileService)
        let pool = [makeArticle(id: "a", category: .technology)]

        let result = try await sut.scoredArticles(from: pool, topN: 5)
        #expect(result.isEmpty)
    }

    @Test("Filters out zero-score articles")
    func filtersZeroScores() async throws {
        let profileService = MockInterestProfileService()
        try await profileService.upsert(
            topicID: "technology", displayName: "Technology",
            weightDelta: 1, source: .seed, category: "technology",
        )
        let sut = LiveForYouService(profileService: profileService)

        let pool = [
            makeArticle(id: "tech", category: .technology), // matches
            makeArticle(id: "sports", category: .sports), // doesn't match
        ]
        let result = try await sut.scoredArticles(from: pool, topN: 5)

        #expect(result.count == 1)
        #expect(result.first?.article.id == "tech")
    }

    @Test("Sorts by score descending")
    func sortsByScoreDescending() async throws {
        let profileService = MockInterestProfileService()
        // Create 3 seed topics with varying weights so each category
        // produces a different score.
        try await profileService.upsert(
            topicID: "technology", displayName: "Technology",
            weightDelta: 5, source: .seed, category: "technology",
        )
        try await profileService.upsert(
            topicID: "science", displayName: "Science",
            weightDelta: 3, source: .seed, category: "science",
        )
        try await profileService.upsert(
            topicID: "health", displayName: "Health",
            weightDelta: 1, source: .seed, category: "health",
        )
        let sut = LiveForYouService(profileService: profileService)

        let pool = [
            makeArticle(id: "h", category: .health),
            makeArticle(id: "t", category: .technology),
            makeArticle(id: "s", category: .science),
        ]
        let result = try await sut.scoredArticles(from: pool, topN: 5)

        // technology > science > health based on weight contribution
        #expect(result.map(\.article.id) == ["t", "s", "h"])
    }

    @Test("Caps results at topN")
    func capsAtTopN() async throws {
        let profileService = MockInterestProfileService()
        try await profileService.upsert(
            topicID: "technology", displayName: "Technology",
            weightDelta: 1, source: .seed, category: "technology",
        )
        let sut = LiveForYouService(profileService: profileService)

        let pool = (0 ..< 10).map { makeArticle(id: "a-\($0)", category: .technology) }
        let result = try await sut.scoredArticles(from: pool, topN: 3)

        #expect(result.count == 3)
    }

    @Test("explanation displays Title-cased matched topics joined by commas")
    func explanationFormat() {
        let profileService = MockInterestProfileService()
        let sut = LiveForYouService(profileService: profileService)

        let result = sut.explanation(for: ["artificial-intelligence", "climate-change"])
        #expect(result == "Artificial Intelligence, Climate Change")
    }

    @Test("explanation caps at 3 topics")
    func explanationCapsAtThree() {
        let profileService = MockInterestProfileService()
        let sut = LiveForYouService(profileService: profileService)

        let result = sut.explanation(for: ["a", "b", "c", "d", "e"])
        let count = result.split(separator: ",").count
        #expect(count == 3)
    }

    @Test("explanation returns empty string for empty matched topics")
    func explanationEmptyForNoMatches() {
        let profileService = MockInterestProfileService()
        let sut = LiveForYouService(profileService: profileService)
        #expect(sut.explanation(for: []).isEmpty)
    }

    // MARK: - Read / bookmarked filter

    @Test("Articles already in reading history are excluded from results")
    func excludesReadArticles() async throws {
        let profileService = MockInterestProfileService()
        try await profileService.upsert(
            topicID: "technology", displayName: "Technology",
            weightDelta: 1, source: .seed, category: "technology",
        )
        let storageService = MockStorageService()
        let alreadyRead = makeArticle(id: "read", category: .technology)
        let unread = makeArticle(id: "unread", category: .technology)
        try await storageService.markArticleAsRead(alreadyRead)

        let sut = LiveForYouService(
            profileService: profileService,
            storageService: storageService,
        )

        let result = try await sut.scoredArticles(from: [alreadyRead, unread], topN: 5)
        #expect(result.map(\.article.id) == ["unread"])
    }

    @Test("Articles already bookmarked are excluded from results")
    func excludesBookmarkedArticles() async throws {
        let profileService = MockInterestProfileService()
        try await profileService.upsert(
            topicID: "technology", displayName: "Technology",
            weightDelta: 1, source: .seed, category: "technology",
        )
        let storageService = MockStorageService()
        let bookmarked = makeArticle(id: "saved", category: .technology)
        let fresh = makeArticle(id: "fresh", category: .technology)
        try await storageService.saveArticle(bookmarked)

        let sut = LiveForYouService(
            profileService: profileService,
            storageService: storageService,
        )

        let result = try await sut.scoredArticles(from: [bookmarked, fresh], topN: 5)
        #expect(result.map(\.article.id) == ["fresh"])
    }

    @Test("Without storageService, filtering is a no-op")
    func noFilteringWithoutStorageService() async throws {
        let profileService = MockInterestProfileService()
        try await profileService.upsert(
            topicID: "technology", displayName: "Technology",
            weightDelta: 1, source: .seed, category: "technology",
        )
        let sut = LiveForYouService(profileService: profileService)

        let pool = [makeArticle(id: "a", category: .technology)]
        let result = try await sut.scoredArticles(from: pool, topN: 5)
        #expect(result.count == 1)
    }
}
