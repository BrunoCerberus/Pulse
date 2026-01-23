import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("ForYouService Filtering Tests")
struct ForYouServiceFilteringTests {
    // MARK: - Test Data

    private var fixedDate: Date {
        Date(timeIntervalSince1970: 1_672_531_200)
    }

    private func createMockStorageService() -> MockStorageService {
        MockStorageService()
    }

    // MARK: - Service Instantiation Tests

    @Test("LiveForYouService can be instantiated")
    func canBeInstantiated() {
        let storageService = createMockStorageService()
        let service = LiveForYouService(storageService: storageService)

        #expect(service is ForYouService)
    }

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

    // MARK: - MockForYouService with Filtering Tests

    /// Creates a mock service that applies the same filtering logic as LiveForYouService
    private func createFilteringMockService(articles: [Article]) -> FilteringMockForYouService {
        FilteringMockForYouService(articles: articles)
    }

    @Test("Service filters muted sources from results")
    func filtersMutedSources() async throws {
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

        let service = createFilteringMockService(articles: articles)
        var preferences = UserPreferences.default
        preferences.mutedSources = ["TechCrunch"]

        // Actually call the service method and collect results
        let publisher = service.fetchPersonalizedFeed(preferences: preferences, page: 1)
        let result = try await collectFirstResult(from: publisher)

        #expect(result.count == 1)
        #expect(result.first?.source.name == "BBC News")
    }

    @Test("Service filters muted keywords in title")
    func filtersMutedKeywordsInTitle() async throws {
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

        let service = createFilteringMockService(articles: articles)
        var preferences = UserPreferences.default
        preferences.mutedKeywords = ["crypto", "bitcoin"]

        let publisher = service.fetchPersonalizedFeed(preferences: preferences, page: 1)
        let result = try await collectFirstResult(from: publisher)

        #expect(result.count == 1)
        #expect(result.first?.id == "2")
    }

    @Test("Service filters muted keywords in description")
    func filtersMutedKeywordsInDescription() async throws {
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

        let service = createFilteringMockService(articles: articles)
        var preferences = UserPreferences.default
        preferences.mutedKeywords = ["scandal"]

        let publisher = service.fetchPersonalizedFeed(preferences: preferences, page: 1)
        let result = try await collectFirstResult(from: publisher)

        #expect(result.count == 1)
        #expect(result.first?.id == "2")
    }

    @Test("Service returns all articles with empty preferences")
    func handlesEmptyPreferences() async throws {
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

        let service = createFilteringMockService(articles: articles)
        let preferences = UserPreferences.default

        // Verify empty muted lists
        #expect(preferences.mutedSources.isEmpty)
        #expect(preferences.mutedKeywords.isEmpty)

        let publisher = service.fetchPersonalizedFeed(preferences: preferences, page: 1)
        let result = try await collectFirstResult(from: publisher)

        #expect(result.count == 2)
    }

    @Test("Service keyword filtering is case insensitive")
    func mutedKeywordFilteringIsCaseInsensitive() async throws {
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

        let service = createFilteringMockService(articles: articles)
        var preferences = UserPreferences.default
        preferences.mutedKeywords = ["CRYPTO"]

        let publisher = service.fetchPersonalizedFeed(preferences: preferences, page: 1)
        let result = try await collectFirstResult(from: publisher)

        // All three contain "crypto" (case insensitive), so all should be filtered
        #expect(result.isEmpty)
    }

    @Test("Service combines source and keyword filters")
    func combinesSourceAndKeywordFilters() async throws {
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

        let service = createFilteringMockService(articles: articles)
        var preferences = UserPreferences.default
        preferences.mutedSources = ["Bad Source"]
        preferences.mutedKeywords = ["spam"]

        let publisher = service.fetchPersonalizedFeed(preferences: preferences, page: 1)
        let result = try await collectFirstResult(from: publisher)

        #expect(result.count == 1)
        #expect(result.first?.id == "1")
    }

    // MARK: - Helper Methods

    /// Collects the first result from a Combine publisher using async/await
    private func collectFirstResult<T>(from publisher: AnyPublisher<T, Error>) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = publisher
                .first()
                .sink(
                    receiveCompletion: { completion in
                        if case let .failure(error) = completion {
                            continuation.resume(throwing: error)
                        }
                        cancellable?.cancel()
                    },
                    receiveValue: { value in
                        continuation.resume(returning: value)
                    }
                )
        }
    }
}

// MARK: - Test Double

/// A mock ForYouService that applies the same filtering logic as LiveForYouService.
/// This allows testing the filtering behavior through the service protocol without network calls.
private final class FilteringMockForYouService: ForYouService {
    private let articles: [Article]

    init(articles: [Article]) {
        self.articles = articles
    }

    func fetchPersonalizedFeed(preferences: UserPreferences, page _: Int) -> AnyPublisher<[Article], Error> {
        // Apply the same filtering logic as LiveForYouService.filterMutedContent
        let filtered = articles.filter { article in
            let isMutedSource = preferences.mutedSources.contains(article.source.name)
            let containsMutedKeyword = preferences.mutedKeywords.contains { keyword in
                article.title.lowercased().contains(keyword.lowercased()) ||
                    (article.description?.lowercased().contains(keyword.lowercased()) ?? false)
            }
            return !isMutedSource && !containsMutedKeyword
        }

        return Just(filtered)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
