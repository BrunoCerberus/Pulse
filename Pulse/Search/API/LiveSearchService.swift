import Combine
import EntropyCore
import Foundation

/// Search service that searches articles from Supabase backend with Guardian API fallback.
///
/// When Supabase is configured, searches are performed against the RSS aggregator database
/// using PostgreSQL text search. Falls back to Guardian API when Supabase is not configured.
final class LiveSearchService: APIRequest, SearchService {
    private let recentSearchesKey = "pulse.recentSearches"
    private let maxRecentSearches = 10
    private let useSupabase: Bool

    override init() {
        useSupabase = SupabaseConfig.isConfigured
        super.init()

        if useSupabase {
            Logger.shared.service("LiveSearchService: using Supabase backend", level: .info)
        } else {
            Logger.shared.service("LiveSearchService: Supabase not configured, using Guardian API", level: .warning)
        }
    }

    func search(query: String, page: Int, sortBy: String) -> AnyPublisher<[Article], Error> {
        saveRecentSearch(query)

        if useSupabase {
            return searchSupabase(query: query, page: page, sortBy: sortBy)
                .catch { [weak self] error -> AnyPublisher<[Article], Error> in
                    Logger.shared.service("LiveSearchService: Supabase search failed, falling back to Guardian - \(error.localizedDescription)", level: .warning)
                    return self?.searchGuardian(query: query, page: page, sortBy: sortBy) ?? Fail(error: error).eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
        }
        return searchGuardian(query: query, page: page, sortBy: sortBy)
    }

    func getSuggestions(for query: String) -> AnyPublisher<[String], Never> {
        let recentSearches = getRecentSearches()
        let filtered = recentSearches.filter {
            $0.lowercased().contains(query.lowercased())
        }
        return Just(filtered).eraseToAnyPublisher()
    }

    // MARK: - Supabase Search

    private func searchSupabase(query: String, page: Int, sortBy _: String) -> AnyPublisher<[Article], Error> {
        // Edge Functions search endpoint uses full-text search with proper pagination
        let pageSize = 20
        return fetchRequest(
            target: SupabaseAPI.search(query: query, page: page, pageSize: pageSize),
            dataType: [SupabaseSearchResult].self
        )
        .map { results in
            results.map { $0.toArticle() }
        }
        .handleEvents(receiveOutput: { articles in
            Logger.shared.service("LiveSearchService: Supabase returned \(articles.count) results for '\(query)' (page \(page))", level: .debug)
        })
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    // MARK: - Guardian Search (Fallback)

    private func searchGuardian(query: String, page: Int, sortBy: String) -> AnyPublisher<[Article], Error> {
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

    // MARK: - Helpers

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
