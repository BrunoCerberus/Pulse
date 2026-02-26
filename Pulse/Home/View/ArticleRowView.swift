import SwiftUI

struct ArticleRowView: View {
    let item: ArticleViewItem
    let onTap: () -> Void
    let onBookmark: () -> Void
    let onShare: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    if let category = item.category {
                        Text(category.displayName)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(category.color)
                    }

                    Text(item.title)
                        .font(.headline)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.primary)

                    if let description = item.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    HStack {
                        Text(item.sourceName)
                            .font(.caption)
                            .fontWeight(.medium)

                        Text("•")
                            .font(.caption)

                        Text(item.formattedDate)
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }

                Spacer()

                if let imageURL = item.imageURL {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(.quaternary)
                                .overlay {
                                    ProgressView()
                                }
                                .accessibilityHidden(true)
                        case let .success(image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .clipped()
                                .accessibilityLabel(item.title)
                        case .failure:
                            Rectangle()
                                .fill(.quaternary)
                                .overlay {
                                    Image(systemName: "photo")
                                        .foregroundStyle(.secondary)
                                }
                                .accessibilityHidden(true)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding()
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            String(
                format: AppLocalization.shared.localized("article_row.accessibility_label"),
                item.title,
                item.sourceName,
                item.formattedDate
            )
        )
        .accessibilityHint(AppLocalization.shared.localized("accessibility.read_article"))
        .contextMenu {
            Button {
                onBookmark()
            } label: {
                Label(AppLocalization.shared.localized("article.bookmark"), systemImage: "bookmark")
            }

            Button {
                onShare()
            } label: {
                Label(AppLocalization.shared.localized("article.share"), systemImage: "square.and.arrow.up")
            }
        }

        Divider()
            .padding(.leading)
    }
}

#Preview {
    ArticleRowView(
        item: ArticleViewItem(
            from: Article(
                title: "Sample Article Title That Might Be Quite Long",
                description: "This is a sample description for the article.",
                source: ArticleSource(id: nil, name: "Sample Source"),
                url: "https://example.com",
                imageURL: "https://picsum.photos/200",
                publishedAt: Date(),
                category: .technology
            )
        ),
        onTap: {},
        onBookmark: {},
        onShare: {}
    )
    .preferredColorScheme(.dark)
}
