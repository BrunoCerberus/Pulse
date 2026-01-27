import Combine
import EntropyCore
import Foundation
import Testing

// MARK: - Live Service Protocol Conformance Tests

@Suite("Live Services Protocol Conformance Tests")
struct LiveServicesProtocolTests {
    @Test("LiveNewsService conforms to NewsService protocol")
    func liveNewsServiceConformance() {
        let service = LiveNewsService()
        #expect(service is NewsService)
    }

    @Test("LiveSearchService conforms to SearchService protocol")
    func liveSearchServiceConformance() {
        let service = LiveSearchService()
        #expect(service is SearchService)
    }

    @Test("LiveNewsService fetchTopHeadlines returns correct publisher type")
    func newsServiceFetchTopHeadlinesType() {
        let service = LiveNewsService()
        let publisher = service.fetchTopHeadlines(country: "us", page: 1)
        let typeCheck: AnyPublisher<[Article], Error> = publisher
        #expect(typeCheck is AnyPublisher<[Article], Error>)
    }

    @Test("LiveSearchService search returns correct publisher type")
    func searchServiceSearchType() {
        let service = LiveSearchService()
        let publisher = service.search(query: "test", page: 1, sortBy: "relevance")
        let typeCheck: AnyPublisher<[Article], Error> = publisher
        #expect(typeCheck is AnyPublisher<[Article], Error>)
    }
}
