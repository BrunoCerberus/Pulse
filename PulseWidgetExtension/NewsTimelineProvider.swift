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
            family: context.family
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
                imageData: nil
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
        let articleLimit: Int
        switch context.family {
        case .systemSmall: articleLimit = 1
        case .systemMedium: articleLimit = 2
        case .systemLarge: articleLimit = 3
        default: articleLimit = 2
        }

        let articlesToFetch = Array(sharedArticles.prefix(articleLimit))

        // Download images for articles
        downloadImages(for: articlesToFetch) { widgetArticles in
            let entry = NewsTimelineEntry(
                date: Date(),
                articles: widgetArticles,
                family: context.family
            )

            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }

    private func downloadImages(for articles: [SharedArticle], completion: @escaping ([WidgetArticle]) -> Void) {
        let group = DispatchGroup()
        var imageDataDict: [String: Data] = [:]
        let lock = NSLock()

        for article in articles {
            guard let urlString = article.imageURL,
                  let url = URL(string: urlString)
            else {
                continue
            }

            group.enter()

            let task = URLSession.shared.dataTask(with: url) { data, response, _ in
                defer { group.leave() }

                guard let data = data,
                      let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200
                else {
                    return
                }

                lock.lock()
                imageDataDict[article.id] = data
                lock.unlock()
            }
            task.resume()
        }

        group.notify(queue: .main) {
            let widgetArticles = articles.map { article in
                WidgetArticle(
                    id: article.id,
                    title: article.title,
                    source: article.source,
                    imageData: imageDataDict[article.id]
                )
            }
            completion(widgetArticles)
        }
    }
}
