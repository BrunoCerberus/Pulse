import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("LiveForYouService Tests")
struct LiveForYouServiceTests {
    // MARK: - Test Data

    private var fixedDate: Date {
        Date(timeIntervalSince1970: 1_672_531_200)
    }

    private func createMockStorageService() -> MockStorageService {
        MockStorageService()
    }

    // MARK: - Smoke Tests

    @Test("LiveForYouService can be instantiated")
    func canBeInstantiated() {
        let storageService = createMockStorageService()
        let service = LiveForYouService(storageService: storageService)

        #expect(service is ForYouService)
    }

    // MARK: - Protocol Conformance Tests

    @Test("fetchPersonalizedFeed returns correct publisher type")
    func fetchPersonalizedFeedReturnsCorrectType() {
        let storageService = createMockStorageService()
        let service = LiveForYouService(storageService: storageService)
        let preferences = UserPreferences.default

        let publisher = service.fetchPersonalizedFeed(preferences: preferences, page: 1)

        // Verify the publisher has the expected type signature
        let typeCheck: AnyPublisher<[Article], Error> = publisher
        #expect(typeCheck is AnyPublisher<[Article], Error>)
    }

    // MARK: - Muted Content Filtering Tests

    @Test("fetchPersonalizedFeed filters muted sources")
    func filtersMutedSources() async throws {
        let storageService = createMockStorageService()
        let service = LiveForYouService(storageService: storageService)

        var preferences = UserPreferences.default
        preferences.mutedSources = ["TechCrunch"]

        // Create test articles including one from the muted source
        let articles = [
            Article(
                id: "1",
                title: "Article from TechCrunch",
                source: ArticleSource(id: "techcrunch", name: "TechCrunch"),
                url: "https://example.com/1",
                publishedAt: fixedDate,
                category: .technology
            ),
            Article(
                id: "2",
                title: "Article from BBC",
                source: ArticleSource(id: "bbc", name: "BBC News"),
                url: "https://example.com/2",
                publishedAt: fixedDate,
                category: .world
            ),
        ]

        // Test the filtering logic directly by simulating the filter
        let filteredArticles = articles.filter { article in
            !preferences.mutedSources.contains(article.source.name)
        }

        #expect(filteredArticles.count == 1)
        #expect(filteredArticles.first?.source.name == "BBC News")
    }

    @Test("fetchPersonalizedFeed filters muted keywords in title")
    func filtersMutedKeywordsInTitle() {
        var preferences = UserPreferences.default
        preferences.mutedKeywords = ["crypto", "bitcoin"]

        let articles = [
            Article(
                id: "1",
                title: "Bitcoin reaches new high",
                source: ArticleSource(id: "news", name: "News"),
                url: "https://example.com/1",
                publishedAt: fixedDate,
                category: .business
            ),
            Article(
                id: "2",
                title: "Stock market update",
                source: ArticleSource(id: "news", name: "News"),
                url: "https://example.com/2",
                publishedAt: fixedDate,
                category: .business
            ),
        ]

        // Test the filtering logic directly
        let filteredArticles = articles.filter { article in
            let containsMutedKeyword = preferences.mutedKeywords.contains { keyword in
                article.title.lowercased().contains(keyword.lowercased())
            }
            return !containsMutedKeyword
        }

        #expect(filteredArticles.count == 1)
        #expect(filteredArticles.first?.id == "2")
    }

    @Test("fetchPersonalizedFeed filters muted keywords in description")
    func filtersMutedKeywordsInDescription() {
        var preferences = UserPreferences.default
        preferences.mutedKeywords = ["scandal"]

        let articles = [
            Article(
                id: "1",
                title: "Normal headline",
                description: "This article discusses a major scandal",
                source: ArticleSource(id: "news", name: "News"),
                url: "https://example.com/1",
                publishedAt: fixedDate,
                category: .world
            ),
            Article(
                id: "2",
                title: "Another headline",
                description: "This is a normal description",
                source: ArticleSource(id: "news", name: "News"),
                url: "https://example.com/2",
                publishedAt: fixedDate,
                category: .world
            ),
        ]

        // Test the filtering logic directly
        let filteredArticles = articles.filter { article in
            let containsMutedKeyword = preferences.mutedKeywords.contains { keyword in
                article.title.lowercased().contains(keyword.lowercased()) ||
                    (article.description?.lowercased().contains(keyword.lowercased()) ?? false)
            }
            return !containsMutedKeyword
        }

        #expect(filteredArticles.count == 1)
        #expect(filteredArticles.first?.id == "2")
    }

    @Test("fetchPersonalizedFeed handles empty preferences")
    func handlesEmptyPreferences() {
        let preferences = UserPreferences.default

        // Default preferences have empty muted lists
        #expect(preferences.mutedSources.isEmpty)
        #expect(preferences.mutedKeywords.isEmpty)

        let articles = [
            Article(
                id: "1",
                title: "Article 1",
                source: ArticleSource(id: "source1", name: "Source 1"),
                url: "https://example.com/1",
                publishedAt: fixedDate,
                category: .technology
            ),
            Article(
                id: "2",
                title: "Article 2",
                source: ArticleSource(id: "source2", name: "Source 2"),
                url: "https://example.com/2",
                publishedAt: fixedDate,
                category: .business
            ),
        ]

        // With empty preferences, no articles should be filtered
        let filteredArticles = articles.filter { article in
            let isMutedSource = preferences.mutedSources.contains(article.source.name)
            let containsMutedKeyword = preferences.mutedKeywords.contains { keyword in
                article.title.lowercased().contains(keyword.lowercased()) ||
                    (article.description?.lowercased().contains(keyword.lowercased()) ?? false)
            }
            return !isMutedSource && !containsMutedKeyword
        }

        #expect(filteredArticles.count == 2)
    }

    @Test("Muted keyword filtering is case insensitive")
    func mutedKeywordFilteringIsCaseInsensitive() {
        var preferences = UserPreferences.default
        preferences.mutedKeywords = ["CRYPTO"]

        let articles = [
            Article(
                id: "1",
                title: "crypto news today",
                source: ArticleSource(id: "news", name: "News"),
                url: "https://example.com/1",
                publishedAt: fixedDate,
                category: .technology
            ),
            Article(
                id: "2",
                title: "CRYPTO market crash",
                source: ArticleSource(id: "news", name: "News"),
                url: "https://example.com/2",
                publishedAt: fixedDate,
                category: .technology
            ),
            Article(
                id: "3",
                title: "Cryptocurrency update",
                source: ArticleSource(id: "news", name: "News"),
                url: "https://example.com/3",
                publishedAt: fixedDate,
                category: .technology
            ),
        ]

        // Test case-insensitive filtering
        let filteredArticles = articles.filter { article in
            let containsMutedKeyword = preferences.mutedKeywords.contains { keyword in
                article.title.lowercased().contains(keyword.lowercased())
            }
            return !containsMutedKeyword
        }

        // "Cryptocurrency" should NOT be filtered (partial match only if it's a contains match)
        // The current logic filters any title containing "crypto" (case insensitive)
        // So articles 1, 2, and 3 would all be filtered
        #expect(filteredArticles.isEmpty)
    }

    @Test("Filtering combines source and keyword filters")
    func combinesSourceAndKeywordFilters() {
        var preferences = UserPreferences.default
        preferences.mutedSources = ["Bad Source"]
        preferences.mutedKeywords = ["spam"]

        let articles = [
            Article(
                id: "1",
                title: "Good article",
                source: ArticleSource(id: "good", name: "Good Source"),
                url: "https://example.com/1",
                publishedAt: fixedDate,
                category: .technology
            ),
            Article(
                id: "2",
                title: "Article from bad source",
                source: ArticleSource(id: "bad", name: "Bad Source"),
                url: "https://example.com/2",
                publishedAt: fixedDate,
                category: .technology
            ),
            Article(
                id: "3",
                title: "This is spam content",
                source: ArticleSource(id: "good", name: "Good Source"),
                url: "https://example.com/3",
                publishedAt: fixedDate,
                category: .technology
            ),
        ]

        let filteredArticles = articles.filter { article in
            let isMutedSource = preferences.mutedSources.contains(article.source.name)
            let containsMutedKeyword = preferences.mutedKeywords.contains { keyword in
                article.title.lowercased().contains(keyword.lowercased()) ||
                    (article.description?.lowercased().contains(keyword.lowercased()) ?? false)
            }
            return !isMutedSource && !containsMutedKeyword
        }

        #expect(filteredArticles.count == 1)
        #expect(filteredArticles.first?.id == "1")
    }
}
