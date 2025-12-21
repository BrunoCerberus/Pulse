import Combine
import EntropyCore
import Foundation

final class LiveSearchService: APIRequest, SearchService {
    private let recentSearchesKey = "pulse.recentSearches"
    private let maxRecentSearches = 10

    func search(query: String, page: Int, sortBy: String) -> AnyPublisher<[Article], Error> {
        saveRecentSearch(query)

        let guardianOrderBy = mapSortOrder(sortBy)

        return fetchRequest(
            target: GuardianAPI.search(
                query: query,
                section: nil,
                page: page,
                pageSize: 20,
                orderBy: guardianOrderBy
            ),
            dataType: GuardianResponse.self
        )
        .map { response in
            response.response.results.compactMap { $0.toArticle() }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func getSuggestions(for query: String) -> AnyPublisher<[String], Never> {
        let recentSearches = getRecentSearches()
        let filtered = recentSearches.filter {
            $0.lowercased().contains(query.lowercased())
        }
        return Just(filtered).eraseToAnyPublisher()
    }

    private func mapSortOrder(_ newsAPISortBy: String) -> String {
        switch newsAPISortBy.lowercased() {
        case "relevancy":
            return "relevance"
        case "popularity":
            return "relevance"
        case "publishedat":
            return "newest"
        default:
            return "relevance"
        }
    }

    private func saveRecentSearch(_ query: String) {
        var searches = getRecentSearches()
        searches.removeAll { $0.lowercased() == query.lowercased() }
        searches.insert(query, at: 0)
        if searches.count > maxRecentSearches {
            searches = Array(searches.prefix(maxRecentSearches))
        }
        UserDefaults.standard.set(searches, forKey: recentSearchesKey)
    }

    private func getRecentSearches() -> [String] {
        UserDefaults.standard.stringArray(forKey: recentSearchesKey) ?? []
    }
}
