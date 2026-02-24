import Foundation

/// Represents all navigable destinations in the app.
///
/// Used with NavigationStack's `navigationDestination(for: Page.self)` to enable
/// type-safe, coordinator-driven navigation throughout the app.
enum Page: Hashable {
    /// Navigate to article detail view
    case articleDetail(Article)

    /// Navigate to media detail view (videos/podcasts)
    case mediaDetail(Article)

    /// Navigate to settings view
    case settings

    /// Navigate to reading history view
    case readingHistory
}
