import Combine
import Foundation

/// Protocol defining the interface for fetching personalized article feeds.
///
/// This protocol provides personalized content based on user preferences,
/// including followed topics and reading history. This is a **Premium** feature.
///
/// The default implementation (`LiveForYouService`) uses Supabase to fetch
/// articles matching the user's topic preferences.
protocol ForYouService {
    /// Fetches a personalized feed based on user preferences.
    /// - Parameters:
    ///   - preferences: The user's preferences including followed topics.
    ///   - page: Page number for pagination (1-indexed).
    /// - Returns: Publisher emitting personalized articles or an error.
    func fetchPersonalizedFeed(preferences: UserPreferences, page: Int) -> AnyPublisher<[Article], Error>
}
