import EntropyCore
import Foundation
import WidgetKit

/// Manages data sharing between the main app and the widget extension
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

/// Lightweight article model for widget data transfer
struct SharedWidgetArticle: Codable {
    let id: String
    let title: String
    let source: String?
    let imageURL: String?
}
