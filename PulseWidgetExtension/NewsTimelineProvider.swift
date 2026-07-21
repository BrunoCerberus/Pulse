import Foundation
import WidgetKit

struct NewsTimelineEntry: TimelineEntry {
    let date: Date
    let articles: [WidgetArticle]?
    let family: WidgetFamily
}

struct NewsTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> NewsTimelineEntry {
        NewsTimelineEntry(
            date: Date(),
            articles: nil,
            family: context.family,
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (NewsTimelineEntry) -> Void) {
        let sharedArticles = SharedDataManager.shared.getArticles()
        if sharedArticles.isEmpty {
            completion(NewsTimelineEntry(date: Date(), articles: nil, family: context.family))
            return
        }

        // For snapshot, return articles without images for speed
        let widgetArticles = sharedArticles.map { article in
            WidgetArticle(
                id: article.id,
                title: article.title,
                source: article.source,
                imageData: nil,
            )
        }
        completion(NewsTimelineEntry(date: Date(), articles: widgetArticles, family: context.family))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NewsTimelineEntry>) -> Void) {
        let sharedArticles = SharedDataManager.shared.getArticles()

        if sharedArticles.isEmpty {
            let entry = NewsTimelineEntry(date: Date(), articles: nil, family: context.family)
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
            completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
            return
        }

        // Limit articles based on widget family
        let articleLimit = switch context.family {
        case .systemSmall: 1
        case .systemMedium: 2
        case .systemLarge: 3
        default: 2
        }

        let articlesToFetch = Array(sharedArticles.prefix(articleLimit))

        // Download images for articles
        downloadImages(for: articlesToFetch) { widgetArticles in
            let entry = NewsTimelineEntry(
                date: Date(),
                articles: widgetArticles,
                family: context.family,
            )

            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }

    private func downloadImages(for articles: [SharedArticle], completion: @escaping ([WidgetArticle]) -> Void) {
        let group = DispatchGroup()
        let protectedDict = LockedImageDataDict()

        for article in articles {
            guard let urlString = article.imageURL,
                  let url = URL(string: urlString),
                  isSafeImageURL(url)
            else {
                continue
            }

            group.enter()

            let task = URLSession.shared.dataTask(with: url) { data, response, _ in
                defer { group.leave() }

                guard let data,
                      let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200
                else {
                    return
                }

                protectedDict.set(data, for: article.id)
            }
            task.resume()
        }

        group.notify(queue: .main) {
            let snapshot = protectedDict.snapshot()
            let widgetArticles = articles.map { article in
                WidgetArticle(
                    id: article.id,
                    title: article.title,
                    source: article.source,
                    imageData: snapshot[article.id],
                )
            }
            completion(widgetArticles)
        }
    }

    /// Rejects non-HTTPS image URLs to avoid leaking article metadata over
    /// plaintext connections. The widget only downloads images for display, so
    /// this is a best-effort defense — the tight widget memory budget and
    /// restricted networking make exfiltration impractical.
    private func isSafeImageURL(_ url: URL) -> Bool {
        url.scheme?.lowercased() == "https"
    }
}

/// Thread-safe dictionary wrapper for image downloads to avoid
/// mutation of captured vars in `@Sendable` closures.
private final class LockedImageDataDict: Sendable {
    private let lock = NSLock()
    private nonisolated(unsafe) var dict: [String: Data] = [:]

    func set(_ data: Data, for key: String) {
        lock.lock()
        dict[key] = data
        lock.unlock()
    }

    func snapshot() -> [String: Data] {
        lock.lock()
        defer { lock.unlock() }
        return dict
    }
}
