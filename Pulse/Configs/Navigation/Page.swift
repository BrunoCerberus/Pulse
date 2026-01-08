import Foundation

/// Represents all navigable destinations in the app.
///
/// Used with NavigationStack's `navigationDestination(for: Page.self)` to enable
/// type-safe, coordinator-driven navigation throughout the app.
enum Page: Hashable {
    /// Navigate to article detail view
    case articleDetail(Article)

    /// Navigate to summary detail view (AI-summarized article)
    case summaryDetail(SummaryItem)

    /// Navigate to settings view
    case settings
}
