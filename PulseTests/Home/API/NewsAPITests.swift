import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("NewsAPI Tests")
struct NewsAPITests {
    @Test("TopHeadlines endpoint includes country and page")
    func topHeadlinesEndpoint() {
        let api = NewsAPI.topHeadlines(country: "us", page: 1)
        let path = api.path

        #expect(path.contains("/top-headlines"))
        #expect(path.contains("country=us"))
        #expect(path.contains("page=1"))
        #expect(path.contains("pageSize=20"))
    }

    @Test("TopHeadlinesByCategory includes category parameter")
    func topHeadlinesByCategoryEndpoint() {
        let api = NewsAPI.topHeadlinesByCategory(category: .technology, country: "us", page: 1)
        let path = api.path

        #expect(path.contains("/top-headlines"))
        #expect(path.contains("country=us"))
        #expect(path.contains("category="))
        #expect(path.contains("page=1"))
    }

    @Test("Everything endpoint includes query and sort")
    func everythingEndpoint() {
        let api = NewsAPI.everything(query: "swift programming", page: 2, sortBy: "publishedAt")
        let path = api.path

        #expect(path.contains("/everything"))
        #expect(path.contains("q=swift"))
        #expect(path.contains("page=2"))
        #expect(path.contains("sortBy=publishedAt"))
        #expect(path.contains("pageSize=20"))
    }

    @Test("Sources endpoint includes category when provided")
    func sourcesWithCategory() {
        let api = NewsAPI.sources(category: "technology", country: nil)
        let path = api.path

        #expect(path.contains("/sources"))
        #expect(path.contains("category=technology"))
    }

    @Test("Sources endpoint includes country when provided")
    func sourcesWithCountry() {
        let api = NewsAPI.sources(category: nil, country: "us")
        let path = api.path

        #expect(path.contains("/sources"))
        #expect(path.contains("country=us"))
    }

    @Test("Sources endpoint omits nil parameters")
    func sourcesOmitsNilParams() {
        let api = NewsAPI.sources(category: nil, country: nil)
        let path = api.path

        #expect(path.contains("/sources"))
        #expect(!path.contains("category="))
        #expect(!path.contains("country="))
    }

    @Test("API key travels in X-Api-Key header, not query string")
    func apiKeyInHeaderNotQuery() throws {
        let cases: [NewsAPI] = [
            .topHeadlines(country: "us", page: 1),
            .topHeadlinesByCategory(category: .technology, country: "us", page: 1),
            .everything(query: "test", page: 1, sortBy: "relevancy"),
            .sources(category: nil, country: nil),
        ]

        for api in cases {
            // Query string must NOT contain the key — it would leak to logs.
            #expect(!api.path.contains("apiKey="))
            // Header carrier is non-nil and encodes as `X-Api-Key`.
            let header = try #require(api.header)
            let data = try JSONEncoder().encode(header)
            let dict = try #require(try JSONSerialization.jsonObject(with: data) as? [String: String])
            #expect(dict["X-Api-Key"] != nil)
        }
    }

    @Test("All cases use GET method")
    func allCasesUseGet() {
        let cases: [NewsAPI] = [
            .topHeadlines(country: "us", page: 1),
            .topHeadlinesByCategory(category: .business, country: "us", page: 1),
            .everything(query: "test", page: 1, sortBy: "relevancy"),
            .sources(category: nil, country: nil),
        ]

        for api in cases {
            #expect(api.method == .GET)
        }
    }

    @Test("All cases return nil task; header carries API key")
    func allCasesReturnNilTaskAndHeader() {
        let api = NewsAPI.topHeadlines(country: "us", page: 1)
        #expect(api.task == nil)
        #expect(api.header != nil)
    }

    @Test("Base URL is NewsAPI")
    func baseURLIsNewsAPI() {
        let api = NewsAPI.topHeadlines(country: "us", page: 1)
        let path = api.path

        #expect(path.contains("newsapi.org"))
    }

    @Test("Different pages produce different paths")
    func differentPagesProduceDifferentPaths() {
        let api1 = NewsAPI.topHeadlines(country: "us", page: 1)
        let api2 = NewsAPI.topHeadlines(country: "us", page: 2)

        #expect(api1.path != api2.path)
    }
}
