import SwiftUI

struct DigestSummaryCard: View {
    let item: SummaryItem
    let onTap: () -> Void
    let onDelete: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: Spacing.md) {
                thumbnailView

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    aiBadge

                    Text(item.article.title)
                        .font(Typography.headlineSmall)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    metadataRow

                    Text(item.summary)
                        .font(Typography.bodySmall)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassBackground(style: .solid, cornerRadius: CornerRadius.lg)
        }
        .buttonStyle(.plain)
        .pressEffect()
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete Summary", systemImage: "trash")
            }
        }
    }

    @ViewBuilder
    private var thumbnailView: some View {
        if let imageURL = item.article.imageURL, let url = URL(string: imageURL) {
            CachedAsyncImage(url: url, accessibilityLabel: item.article.title) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.Glass.surface)
                    .shimmer(isActive: true)
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous)
                    .stroke(Color.Border.adaptive(for: colorScheme), lineWidth: 0.5)
            }
        } else {
            placeholderImage
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous)
                        .stroke(Color.Border.adaptive(for: colorScheme), lineWidth: 0.5)
                }
        }
    }

    private var placeholderImage: some View {
        Rectangle()
            .fill(Color.Glass.surface)
            .overlay {
                Image(systemName: "newspaper")
                    .foregroundStyle(.tertiary)
            }
    }

    private var aiBadge: some View {
        HStack(spacing: Spacing.xxs) {
            Image(systemName: "sparkles")
                .font(.system(size: IconSize.xs))
            Text("AI Summary")
                .font(Typography.captionSmall)
        }
        .foregroundStyle(Color.Accent.primary)
    }

    private var metadataRow: some View {
        HStack(spacing: Spacing.xs) {
            Text(item.article.source.name)
                .lineLimit(1)

            Circle()
                .fill(.tertiary)
                .frame(width: 3, height: 3)

            Text(item.formattedDate)
                .lineLimit(1)
        }
        .font(Typography.captionLarge)
        .foregroundStyle(.tertiary)
    }
}

#Preview {
    DigestSummaryCard(
        item: SummaryItem(
            article: Article.mockArticles[0],
            summary: "This is a sample AI-generated summary of the article content that provides key insights.",
            generatedAt: Date()
        ),
        onTap: {},
        onDelete: {}
    )
    .padding()
}
