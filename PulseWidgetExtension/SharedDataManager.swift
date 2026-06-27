import Foundation

final class SharedDataManager: Sendable {
    static let shared = SharedDataManager()

    private let appGroupIdentifier = "group.com.bruno.Pulse-News"
    private let articlesKey = "shared_articles"

    init() {}

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    /// Hard cap on the number of articles returned from shared storage. An attacker
    /// who poisons App Group storage can't use a massive JSON payload to cause memory
    /// pressure in the widget process (~120 MB budget). Mirrors `SharedURLQueue`'s
    /// write-side + read-side defense-in-depth (rule 23).
    private static let maxArticlesCount = 10

    func getArticles() -> [SharedArticle] {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: articlesKey)
        else {
            return []
        }

        do {
            let decoded = try JSONDecoder().decode([SharedArticle].self, from: data)
            return decoded.count > Self.maxArticlesCount
                ? Array(decoded.prefix(Self.maxArticlesCount))
                : decoded
        } catch {
            return []
        }
    }

    func saveArticles(_ articles: [SharedArticle]) {
        guard let defaults = sharedDefaults else { return }

        do {
            let data = try JSONEncoder().encode(articles)
            defaults.set(data, forKey: articlesKey)
        } catch {
            // Silent failure for widget
        }
    }
}
