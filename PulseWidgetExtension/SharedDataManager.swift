import Foundation

final class SharedDataManager {
    static let shared = SharedDataManager()

    private let appGroupIdentifier = "group.com.bruno.Pulse-News"
    private let articlesKey = "shared_articles"

    private init() {}

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    func getArticles() -> [SharedArticle] {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: articlesKey)
        else {
            return []
        }

        do {
            return try JSONDecoder().decode([SharedArticle].self, from: data)
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
