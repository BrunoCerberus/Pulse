import WidgetKit

struct NewsTimelineEntry: TimelineEntry {
    let date: Date
    let articles: [SharedArticle]?
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
        let articles = SharedDataManager.shared.getArticles()
        let entry = NewsTimelineEntry(
            date: Date(),
            articles: articles.isEmpty ? nil : articles,
            family: context.family
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NewsTimelineEntry>) -> Void) {
        let articles = SharedDataManager.shared.getArticles()
        let entry = NewsTimelineEntry(
            date: Date(),
            articles: articles.isEmpty ? nil : articles,
            family: context.family
        )

        // Update every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))

        completion(timeline)
    }
}
