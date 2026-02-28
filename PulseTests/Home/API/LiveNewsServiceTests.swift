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

@Suite("GuardianAPI Tests")
struct GuardianAPITests {
    @Test("GuardianAPI search path includes required parameters")
    func searchPathIncludesRequiredParameters() {
        let api = GuardianAPI.search(query: nil, section: nil, page: 1, pageSize: 20, orderBy: "newest")
        let path = api.path
        #expect(path.contains("/search"))
        #expect(path.contains("page=1"))
        #expect(path.contains("page-size=20"))
        #expect(path.contains("order-by=newest"))
        #expect(path.contains("show-fields="))
        #expect(path.contains("api-key="))
    }

    @Test("GuardianAPI search includes query when provided")
    func searchIncludesQuery() {
        let api = GuardianAPI.search(query: "swift", section: nil, page: 1, pageSize: 20, orderBy: "relevance")
        let path = api.path
        #expect(path.contains("q=swift"))
    }

    @Test("GuardianAPI search includes section when provided")
    func searchIncludesSection() {
        let api = GuardianAPI.search(query: nil, section: "technology", page: 1, pageSize: 10, orderBy: "newest")
        let path = api.path
        #expect(path.contains("section=technology"))
    }

    @Test("GuardianAPI search omits empty query")
    func searchOmitsEmptyQuery() {
        let api = GuardianAPI.search(query: "", section: nil, page: 1, pageSize: 20, orderBy: "newest")
        let path = api.path
        #expect(!path.contains("q="))
    }

    @Test("GuardianAPI sections path is correct")
    func sectionsPath() {
        let api = GuardianAPI.sections
        let path = api.path
        #expect(path.contains("/sections"))
        #expect(path.contains("api-key="))
    }

    @Test("GuardianAPI article path includes id")
    func articlePathIncludesId() {
        let api = GuardianAPI.article(id: "world/2024/jan/01/test-article")
        let path = api.path
        #expect(path.contains("/world/2024/jan/01/test-article"))
        #expect(path.contains("show-fields="))
        #expect(path.contains("api-key="))
    }

    @Test("GuardianAPI uses GET method")
    func usesGetMethod() {
        let searchAPI = GuardianAPI.search(query: nil, section: nil, page: 1, pageSize: 20, orderBy: "newest")
        let sectionsAPI = GuardianAPI.sections
        let articleAPI = GuardianAPI.article(id: "test")
        #expect(searchAPI.method == .GET)
        #expect(sectionsAPI.method == .GET)
        #expect(articleAPI.method == .GET)
    }

    @Test("GuardianAPI task is nil")
    func taskIsNil() {
        let api = GuardianAPI.search(query: nil, section: nil, page: 1, pageSize: 20, orderBy: "newest")
        #expect(api.task == nil)
    }

    @Test("GuardianAPI header is nil")
    func headerIsNil() {
        let api = GuardianAPI.search(query: nil, section: nil, page: 1, pageSize: 20, orderBy: "newest")
        #expect(api.header == nil)
    }

    @Test("NewsCategory guardianSection mappings are correct")
    func categoryGuardianSectionMappings() {
        #expect(NewsCategory.world.guardianSection == "world")
        #expect(NewsCategory.business.guardianSection == "business")
        #expect(NewsCategory.technology.guardianSection == "technology")
        #expect(NewsCategory.science.guardianSection == "science")
        #expect(NewsCategory.health.guardianSection == "society")
        #expect(NewsCategory.sports.guardianSection == "sport")
        #expect(NewsCategory.entertainment.guardianSection == "culture")
    }
}
