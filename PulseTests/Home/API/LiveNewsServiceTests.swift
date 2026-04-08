import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("LiveNewsService Tests")
struct LiveNewsServiceTests {
    @Test("LiveNewsService can be instantiated")
    func canBeInstantiated() {
        let service = LiveNewsService()
        // Compile-time protocol conformance check
        let _: any NewsService = service
    }

    @Test("fetchTopHeadlines returns correct publisher type")
    func fetchTopHeadlinesReturnsCorrectType() {
        let service = LiveNewsService()
        let publisher = service.fetchTopHeadlines(language: "en", country: "us", page: 1)
        // Type annotation verifies publisher type at compile time
        let _: AnyPublisher<[Article], Error> = publisher
    }

    @Test("fetchBreakingNews returns correct publisher type")
    func fetchBreakingNewsReturnsCorrectType() {
        let service = LiveNewsService()
        let publisher = service.fetchBreakingNews(language: "en", country: "us")
        let _: AnyPublisher<[Article], Error> = publisher
    }

    @Test("fetchTopHeadlines by category returns correct publisher type")
    func fetchTopHeadlinesByCategoryReturnsCorrectType() {
        let service = LiveNewsService()
        let publisher = service.fetchTopHeadlines(category: .technology, language: "en", country: "us", page: 1)
        let _: AnyPublisher<[Article], Error> = publisher
    }

    @Test("fetchArticle returns correct publisher type")
    func fetchArticleReturnsCorrectType() {
        let service = LiveNewsService()
        let publisher = service.fetchArticle(id: "test/article/id")
        let _: AnyPublisher<Article, Error> = publisher
    }
}
