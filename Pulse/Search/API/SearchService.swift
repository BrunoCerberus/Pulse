import Foundation
import Combine
import EntropyCore

protocol SearchService {
    func search(query: String, page: Int, sortBy: String) -> AnyPublisher<[Article], Error>
    func getSuggestions(for query: String) -> AnyPublisher<[String], Never>
}

final class LiveSearchService: APIRequest, SearchService {
    private let recentSearchesKey = "pulse.recentSearches"
    private let maxRecentSearches = 10

    func search(query: String, page: Int, sortBy: String) -> AnyPublisher<[Article], Error> {
        saveRecentSearch(query)

        return fetchRequest(
            target: NewsAPI.everything(query: query, page: page, sortBy: sortBy),
            dataType: NewsResponse.self
        )
        .map { response in
            response.articles.compactMap { $0.toArticle() }
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
