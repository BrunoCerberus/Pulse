import EntropyCore
import Foundation
import WidgetKit

/// Manages data sharing between the main app and the widget extension.
///
/// This singleton persists article data to an App Group shared container,
/// allowing the WidgetKit extension to display recent headlines.
///
/// ## Data Flow
/// 1. Main app calls `saveArticlesForWidget(_:)` with latest articles
/// 2. Articles are converted to lightweight `SharedWidgetArticle` format
/// 3. Data is encoded and saved to App Group UserDefaults
/// 4. `WidgetCenter.reloadAllTimelines()` triggers widget refresh
///
/// ## Optimization
/// - Only saves first 10 articles to minimize storage
/// - Skips save if article IDs haven't changed (hash comparison)
/// - Uses lightweight model to minimize data transfer
final class WidgetDataManager {
    static let shared = WidgetDataManager()

    private let appGroupIdentifier = "group.com.bruno.Pulse-News"
    private let articlesKey = "shared_articles"
    private var lastSavedHash: Int?

    private init() {}

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    /// Saves articles to the shared container for the widget to display
    func saveArticlesForWidget(_ articles: [Article]) {
        guard let defaults = sharedDefaults else {
            Logger.shared.service("Failed to access app group defaults", level: .warning)
            return
        }

        // Convert to shared article format (lightweight for widget)
        let sharedArticles = articles.prefix(10).map { article in
            SharedWidgetArticle(
                id: article.id,
                title: article.title,
                source: article.source.name,
                imageURL: article.displayImageURL
            )
        }

        // Skip encoding and widget reload if data hasn't changed
        let currentHash = sharedArticles.map(\.id).hashValue
        guard currentHash != lastSavedHash else { return }

        do {
            let data = try JSONEncoder().encode(Array(sharedArticles))
            defaults.set(data, forKey: articlesKey)
            lastSavedHash = currentHash
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            Logger.shared.service("Failed to encode articles for widget: \(error)", level: .warning)
        }
    }
}

/// Lightweight article model for widget data transfer.
///
/// Contains only the essential fields needed for widget display,
/// minimizing storage size and encoding/decoding overhead.
struct SharedWidgetArticle: Codable {
    /// Unique article identifier for deeplink navigation.
    let id: String

    /// Article headline displayed in the widget.
    let title: String

    /// News source name (e.g., "The Guardian").
    let source: String?

    /// Thumbnail image URL for widget display.
    let imageURL: String?
}
