import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("LiveSearchService Tests")
struct LiveSearchServiceTests {
    @Test("LiveSearchService can be instantiated")
    func canBeInstantiated() {
        let service = LiveSearchService()
        #expect(service is SearchService)
    }

    @Test("search returns correct publisher type")
    func searchReturnsCorrectType() {
        let service = LiveSearchService()
        let publisher = service.search(query: "test", page: 1, sortBy: "relevance")
        let typeCheck: AnyPublisher<[Article], Error> = publisher
        #expect(typeCheck is AnyPublisher<[Article], Error>)
    }

    @Test("getSuggestions returns correct publisher type")
    func getSuggestionsReturnsCorrectType() {
        let service = LiveSearchService()
        let publisher = service.getSuggestions(for: "test")
        let typeCheck: AnyPublisher<[String], Never> = publisher
        #expect(typeCheck is AnyPublisher<[String], Never>)
    }

    @Test("mapSortOrder maps relevancy to relevance")
    func mapSortOrderMapsRelevancy() {
        let service = LiveSearchService()
        let result = service.mapSortOrder("relevancy")
        #expect(result == "relevance")
    }

    @Test("mapSortOrder maps popularity to relevance")
    func mapSortOrderMapsPopularity() {
        let service = LiveSearchService()
        let result = service.mapSortOrder("popularity")
        #expect(result == "relevance")
    }

    @Test("mapSortOrder maps publishedat to newest")
    func mapSortOrderMapsPublishedAt() {
        let service = LiveSearchService()
        let result = service.mapSortOrder("publishedat")
        #expect(result == "newest")
    }

    @Test("mapSortOrder defaults to relevance")
    func mapSortOrderDefaultsToRelevance() {
        let service = LiveSearchService()
        let result = service.mapSortOrder("unknown")
        #expect(result == "relevance")
    }
}
