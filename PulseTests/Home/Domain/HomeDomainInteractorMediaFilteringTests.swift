import Foundation
@testable import Pulse
import Testing

// MARK: - Media Filtering Tests

extension HomeDomainInteractorTests {
    @Test("Media items are filtered from headlines")
    func mediaItemsFilteredFromHeadlines() async throws {
        let videoArticle = Article(
            id: "video-1",
            title: "Test Video",
            source: ArticleSource(id: "test", name: "Test"),
            url: "https://example.com",
            publishedAt: Date(),
            mediaType: .video
        )
        let regularArticle = Article(
            id: "article-1",
            title: "Test Article",
            source: ArticleSource(id: "test", name: "Test"),
            url: "https://example.com",
            publishedAt: Date()
        )

        mockNewsService.topHeadlinesResult = .success([videoArticle, regularArticle])
        mockNewsService.breakingNewsResult = .success([])

        sut.dispatch(action: .loadInitialData)
        try await Task.sleep(nanoseconds: 500_000_000)

        let state = sut.currentState
        #expect(state.headlines.count == 1)
        #expect(state.headlines.first?.id == regularArticle.id)
        #expect(!state.headlines.contains(where: { $0.isMedia }))
    }

    @Test("Media items are filtered from breaking news")
    func mediaItemsFilteredFromBreakingNews() async throws {
        let podcastArticle = Article(
            id: "podcast-1",
            title: "Test Podcast",
            source: ArticleSource(id: "test", name: "Test"),
            url: "https://example.com",
            publishedAt: Date(),
            mediaType: .podcast
        )
        let regularArticle = Article(
            id: "article-1",
            title: "Test Article",
            source: ArticleSource(id: "test", name: "Test"),
            url: "https://example.com",
            publishedAt: Date()
        )

        mockNewsService.breakingNewsResult = .success([podcastArticle, regularArticle])
        mockNewsService.topHeadlinesResult = .success([])

        sut.dispatch(action: .loadInitialData)
        try await Task.sleep(nanoseconds: 500_000_000)

        let state = sut.currentState
        #expect(state.breakingNews.count == 1)
        #expect(state.breakingNews.first?.id == regularArticle.id)
        #expect(!state.breakingNews.contains(where: { $0.isMedia }))
    }

    @Test("Media items are filtered during pagination")
    func mediaItemsFilteredDuringPagination() async throws {
        // Load initial page with 20 articles to ensure hasMorePages is true
        var initialArticles: [Article] = []
        for index in 0 ..< 20 {
            initialArticles.append(Article(
                id: "article-\(index)",
                title: "Initial Article \(index)",
                source: ArticleSource(id: "test", name: "Test"),
                url: "https://example.com",
                publishedAt: Date()
            ))
        }
        mockNewsService.topHeadlinesResult = .success(initialArticles)
        mockNewsService.breakingNewsResult = .success([])
        sut.dispatch(action: .loadInitialData)
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(sut.currentState.hasMorePages) // Verify pagination is enabled

        // Second page has media items mixed with articles
        let videoArticle = Article(
            id: "video-1",
            title: "Test Video",
            source: ArticleSource(id: "test", name: "Test"),
            url: "https://example.com",
            publishedAt: Date(),
            mediaType: .video
        )
        let newArticle = Article(
            id: "article-new",
            title: "New Article",
            source: ArticleSource(id: "test", name: "Test"),
            url: "https://example.com",
            publishedAt: Date()
        )
        mockNewsService.topHeadlinesResult = .success([videoArticle, newArticle])

        sut.dispatch(action: .loadMoreHeadlines)
        try await Task.sleep(nanoseconds: 500_000_000)

        let state = sut.currentState
        #expect(!state.headlines.contains(where: { $0.isMedia }))
        #expect(state.headlines.count == 21) // 20 initial + 1 new (video filtered)
    }

    @Test("Media items are filtered from category headlines")
    func mediaItemsFilteredFromCategoryHeadlines() async throws {
        let videoArticle = Article(
            id: "video-1",
            title: "Tech Video",
            source: ArticleSource(id: "test", name: "Test"),
            url: "https://example.com",
            publishedAt: Date(),
            category: .technology,
            mediaType: .video
        )
        let regularArticle = Article(
            id: "article-1",
            title: "Tech Article",
            source: ArticleSource(id: "test", name: "Test"),
            url: "https://example.com",
            publishedAt: Date(),
            category: .technology
        )

        mockNewsService.categoryHeadlinesResult = .success([videoArticle, regularArticle])

        sut.dispatch(action: .selectCategory(.technology))
        try await Task.sleep(nanoseconds: 500_000_000)

        let state = sut.currentState
        #expect(state.headlines.count == 1)
        #expect(state.headlines.first?.id == regularArticle.id)
        #expect(!state.headlines.contains(where: { $0.isMedia }))
    }
}
