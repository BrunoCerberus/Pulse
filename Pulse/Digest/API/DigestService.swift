import Combine
import Foundation

/// Service protocol for fetching content for digest generation
protocol DigestService {
    /// Fetch fresh news articles for the given topics
    func fetchFreshNews(for topics: [NewsCategory]) async throws -> [Article]
}
