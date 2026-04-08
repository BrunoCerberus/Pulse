import Combine
import EntropyCore
import Foundation

/// Search service that searches articles from the Supabase backend.
///
/// Searches are performed against the RSS aggregator database
/// using PostgreSQL text search.
final class LiveSearchService: APIRequest, SearchService {
    private let recentSearchesKey = "pulse.recentSearches"
    private let maxRecentSearches = 10
    private let isConfigured: Bool

    override init() {
        isConfigured = SupabaseConfig.isConfigured
        super.init()

        if isConfigured {
            Logger.shared.service("LiveSearchService: using Supabase backend", level: .info)
        } else {
            Logger.shared.service("LiveSearchService: Supabase not configured", level: .error)
        }
    }

    func search(query: String, page: Int, sortBy: String) -> AnyPublisher<[Article], Error> {
        guard isConfigured else {
            return Fail(error: URLError(.badURL, userInfo: [
                NSLocalizedDescriptionKey: "Supabase backend not configured",
            ])).eraseToAnyPublisher()
        }
        saveRecentSearch(query)
        return searchSupabase(query: query, page: page, sortBy: sortBy)
    }

    func getSuggestions(for query: String) -> AnyPublisher<[String], Never> {
        let recentSearches = getRecentSearches()
        let filtered = recentSearches.filter {
            $0.localizedStandardContains(query)
        }
        return Just(filtered).eraseToAnyPublisher()
    }

    // MARK: - Supabase Search

    private func searchSupabase(query: String, page: Int, sortBy _: String) -> AnyPublisher<[Article], Error> {
        let pageSize = 20
        return fetchRequest(
            target: SupabaseAPI.search(query: query, page: page, pageSize: pageSize),
            dataType: [SupabaseSearchResult].self
        )
        .map { results in
            results.map { $0.toArticle() }
        }
        .handleEvents(receiveOutput: { articles in
            let count = articles.count
            Logger.shared.service("LiveSearchService: \(count) results (query length: \(query.count))", level: .debug)
        })
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    // MARK: - Recent Searches

    private func saveRecentSearch(_ query: String) {
        var searches = getRecentSearches()
        searches.removeAll { $0.localizedCaseInsensitiveCompare(query) == .orderedSame }
        searches.insert(query, at: 0)
        if searches.count > maxRecentSearches {
            searches = Array(searches.prefix(maxRecentSearches))
        }
        UserDefaults.standard.set(searches, forKey: recentSearchesKey)
    }

    private func getRecentSearches() -> [String] {
        UserDefaults.standard.stringArray(forKey: recentSearchesKey) ?? []
    }

    func clearRecentSearches() {
        UserDefaults.standard.removeObject(forKey: recentSearchesKey)
    }
}
