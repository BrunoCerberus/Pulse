import Combine
import Foundation

/// Protocol defining the interface for searching articles.
///
/// This protocol provides full-text search capabilities with pagination
/// and query suggestions for autocomplete functionality.
///
/// The default implementation (`LiveSearchService`) uses Supabase full-text
/// search with Guardian API fallback.
protocol SearchService {
    /// Searches for articles matching the given query.
    /// - Parameters:
    ///   - query: The search query string.
    ///   - page: Page number for pagination (1-indexed).
    ///   - sortBy: Sort order for results (e.g., "relevance", "newest", "oldest").
    /// - Returns: Publisher emitting matching articles or an error.
    func search(query: String, page: Int, sortBy: String) -> AnyPublisher<[Article], Error>

    /// Fetches search suggestions for autocomplete.
    /// - Parameter query: The partial query to get suggestions for.
    /// - Returns: Publisher emitting an array of suggested search terms.
    func getSuggestions(for query: String) -> AnyPublisher<[String], Never>
}
