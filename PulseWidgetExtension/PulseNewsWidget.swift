import SwiftUI
import UIKit
import WidgetKit

struct PulseNewsWidget: Widget {
    let kind: String = "PulseNewsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NewsTimelineProvider()) { entry in
            PulseNewsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Top Headlines")
        .description("Stay updated with the latest news headlines.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct PulseNewsWidgetEntryView: View {
    let entry: NewsTimelineEntry

    var body: some View {
        VStack(alignment: .leading, spacing: headerSpacing) {
            // Header
            HStack(spacing: 4) {
                Text("Pulse")
                    .font(entry.family == .systemSmall ? .caption2 : .caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.bottom, 2)

            // Content
            if let articles = entry.articles, !articles.isEmpty {
                VStack(spacing: contentSpacing) {
                    ForEach(Array(articles.prefix(articleLimit(for: entry.family)).enumerated()), id: \.offset) { _, article in
                        ArticleRowView(article: article, family: entry.family)
                    }
                }
            } else {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "newspaper")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            Text("No headlines available")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    Spacer()
                }
            }

            Spacer(minLength: 0)
        }
        .containerBackground(for: .widget) {
            Color(uiColor: .systemBackground)
        }
    }

    private var headerSpacing: CGFloat {
        entry.family == .systemSmall ? 6 : 8
    }

    private var contentSpacing: CGFloat {
        entry.family == .systemSmall ? 8 : 10
    }

    private func articleLimit(for family: WidgetFamily) -> Int {
        switch family {
        case .systemSmall:
            1
        case .systemMedium:
            2
        case .systemLarge:
            3
        default:
            2
        }
    }
}

struct ArticleRowView: View {
    let article: WidgetArticle
    let family: WidgetFamily

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            // Article image
            articleImage
                .frame(width: family == .systemSmall ? 45 : 50, height: family == .systemSmall ? 45 : 50)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            // Article details
            VStack(alignment: .leading, spacing: 3) {
                Text(article.title)
                    .font(.system(size: family == .systemSmall ? 11 : 12, weight: .semibold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                if family != .systemSmall, let source = article.source {
                    Text(source)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
        .frame(height: family == .systemSmall ? 45 : 50)
    }

    @ViewBuilder
    private var articleImage: some View {
        if let imageData = article.imageData,
           let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            // Placeholder when no image available
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.4), Color.blue.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Image(systemName: "newspaper.fill")
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}

#Preview("PulseNewsWidget - Small", as: .systemSmall) {
    PulseNewsWidget()
} timeline: {
    let sampleArticles = [
        WidgetArticle(
            id: "1",
            title: "Breaking: Major Tech Announcement",
            source: "TechNews",
            imageData: nil
        ),
    ]
    NewsTimelineEntry(
        date: Date(),
        articles: sampleArticles,
        family: .systemSmall
    )
}

#Preview("PulseNewsWidget - Medium", as: .systemMedium) {
    PulseNewsWidget()
} timeline: {
    let sampleArticles = [
        WidgetArticle(
            id: "1",
            title: "Breaking: Major Tech Announcement",
            source: "TechNews",
            imageData: nil
        ),
        WidgetArticle(
            id: "2",
            title: "Markets Rally on Economic News",
            source: "Financial Times",
            imageData: nil
        ),
    ]
    NewsTimelineEntry(
        date: Date(),
        articles: sampleArticles,
        family: .systemMedium
    )
}

#Preview("PulseNewsWidget - Large", as: .systemLarge) {
    PulseNewsWidget()
} timeline: {
    let sampleArticles = [
        WidgetArticle(
            id: "1",
            title: "Breaking: Major Tech Announcement",
            source: "TechNews",
            imageData: nil
        ),
        WidgetArticle(
            id: "2",
            title: "Markets Rally on Economic News",
            source: "Financial Times",
            imageData: nil
        ),
        WidgetArticle(
            id: "3",
            title: "Sports Update: Championship Finals",
            source: "ESPN",
            imageData: nil
        ),
    ]
    NewsTimelineEntry(
        date: Date(),
        articles: sampleArticles,
        family: .systemLarge
    )
}
