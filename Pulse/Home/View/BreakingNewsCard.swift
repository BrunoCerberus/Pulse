import EntropyCore
import SwiftUI

// MARK: - Constants

private enum Constants {
    static var breaking: String {
        AppLocalization.shared.localized("home.breaking")
    }
}

// MARK: - BreakingNewsCard

struct BreakingNewsCard: View {
    let item: ArticleViewItem
    let onTap: () -> Void
    var cardWidth: CGFloat = 280

    private var cardHeight: CGFloat {
        cardWidth * (200.0 / 280.0)
    }

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                // Use heroImageURL for carousel cards (higher resolution)
                if let imageURL = item.heroImageURL ?? item.imageURL {
                    CachedAsyncImage(url: imageURL, accessibilityLabel: item.title) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: cardWidth, height: cardHeight)
                            .clipped()
                    } placeholder: {
                        Rectangle()
                            .fill(.quaternary)
                            .overlay {
                                ProgressView()
                            }
                    }
                } else {
                    Rectangle()
                        .fill(.quaternary)
                        .overlay {
                            Image(systemName: "newspaper")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                        }
                }

                LinearGradient(
                    colors: [.clear, .black.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(Constants.breaking)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.red)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 4))

                        Spacer()
                    }

                    Text(item.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)

                    HStack {
                        Text(item.sourceName)
                            .font(.caption)
                            .fontWeight(.medium)

                        Text("•")
                            .font(.caption)

                        Text(item.formattedDate)
                            .font(.caption)
                    }
                    .foregroundStyle(.white.opacity(0.8))
                }
                .padding()
            }
            .frame(width: cardWidth, height: cardHeight)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 4)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            String(
                format: AppLocalization.shared.localized("breaking_news.accessibility_label"),
                item.title,
                item.sourceName,
                item.formattedDate
            )
        )
        .accessibilityHint(AppLocalization.shared.localized("accessibility.read_article"))
    }
}

#Preview {
    BreakingNewsCard(
        item: ArticleViewItem(
            from: Article(
                title: "Breaking: Major News Event Happening Right Now",
                source: ArticleSource(id: nil, name: "News Source"),
                url: "https://example.com",
                imageURL: "https://picsum.photos/300/200",
                publishedAt: Date()
            )
        ),
        onTap: {}
    )
    .padding()
    .preferredColorScheme(.dark)
}
