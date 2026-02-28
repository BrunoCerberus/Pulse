import Combine
import Foundation
@testable import Pulse
import Testing

// MARK: - Live Service Protocol Conformance Tests

@Suite("Live Services Protocol Conformance Tests")
struct LiveServicesProtocolTests {
    @Test("LiveNewsService conforms to NewsService protocol")
    func liveNewsServiceConformance() {
        let service = LiveNewsService()
        let _: any NewsService = service
    }

    @Test("LiveSearchService conforms to SearchService protocol")
    func liveSearchServiceConformance() {
        let service = LiveSearchService()
        let _: any SearchService = service
    }

    @Test("LiveNewsService fetchTopHeadlines returns correct publisher type")
    func newsServiceFetchTopHeadlinesType() {
        let service = LiveNewsService()
        let publisher = service.fetchTopHeadlines(language: "en", country: "us", page: 1)
        let _: AnyPublisher<[Article], Error> = publisher
    }

    @Test("LiveSearchService search returns correct publisher type")
    func searchServiceSearchType() {
        let service = LiveSearchService()
        let publisher = service.search(query: "test", page: 1, sortBy: "relevance")
        let _: AnyPublisher<[Article], Error> = publisher
    }
}
