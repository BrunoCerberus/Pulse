import Combine
import Foundation

/// Protocol defining the interface for fetching media content (videos and podcasts).
///
/// This protocol abstracts the media data layer and provides a clean interface
/// for fetching videos, podcasts, and featured media content.
///
/// The default implementation (`LiveMediaService`) uses Supabase to fetch
/// media content from pre-configured podcast and video sources.
protocol MediaService {
    /// Fetches media items with optional type filtering and pagination.
    /// - Parameters:
    ///   - type: Filter by media type (nil returns both videos and podcasts).
    ///   - language: ISO 639-1 language code for content filtering (e.g., "en", "pt", "es").
    ///   - page: Page number for pagination (1-indexed).
    /// - Returns: Publisher emitting an array of media articles or an error.
    func fetchMedia(type: MediaType?, language: String, page: Int) -> AnyPublisher<[Article], Error>

    /// Fetches featured/trending media items for the carousel.
    /// - Parameters:
    ///   - type: Filter by media type (nil returns both).
    ///   - language: ISO 639-1 language code for content filtering.
    /// - Returns: Publisher emitting featured media articles or an error.
    func fetchFeaturedMedia(type: MediaType?, language: String) -> AnyPublisher<[Article], Error>
}
