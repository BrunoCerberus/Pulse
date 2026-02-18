import Combine
import Foundation

/// Protocol defining the interface for fetching news articles.
///
/// This protocol abstracts the news data layer and provides a clean interface
/// for fetching headlines, breaking news, and individual articles.
///
/// The default implementation (`LiveNewsService`) uses Supabase as the primary
/// backend with automatic fallback to the Guardian API if Supabase is unavailable.
///
/// ## Caching
/// Use `CachingNewsService` to wrap any `NewsService` implementation with
/// in-memory caching and configurable TTL per content type.
protocol NewsService {
    /// Fetches top headlines for a specific country with pagination.
    /// - Parameters:
    ///   - language: ISO 639-1 language code for content filtering (e.g., "en", "pt", "es").
    ///   - country: ISO 3166-1 alpha-2 country code (e.g., "us", "gb").
    ///   - page: Page number for pagination (1-indexed).
    /// - Returns: Publisher emitting an array of articles or an error.
    func fetchTopHeadlines(language: String, country: String, page: Int) -> AnyPublisher<[Article], Error>

    /// Fetches top headlines filtered by category.
    /// - Parameters:
    ///   - category: News category to filter by (e.g., `.technology`, `.sports`).
    ///   - language: ISO 639-1 language code for content filtering.
    ///   - country: ISO 3166-1 alpha-2 country code.
    ///   - page: Page number for pagination (1-indexed).
    /// - Returns: Publisher emitting an array of articles or an error.
    func fetchTopHeadlines(
        category: NewsCategory,
        language: String,
        country: String,
        page: Int
    ) -> AnyPublisher<[Article], Error>

    /// Fetches the latest breaking news articles.
    /// - Parameters:
    ///   - language: ISO 639-1 language code for content filtering.
    ///   - country: ISO 3166-1 alpha-2 country code.
    /// - Returns: Publisher emitting breaking news articles or an error.
    func fetchBreakingNews(language: String, country: String) -> AnyPublisher<[Article], Error>

    /// Fetches a single article by its unique identifier.
    /// - Parameter id: The article's unique identifier (Guardian content ID or Supabase UUID).
    /// - Returns: Publisher emitting the article or an error if not found.
    func fetchArticle(id: String) -> AnyPublisher<Article, Error>
}
