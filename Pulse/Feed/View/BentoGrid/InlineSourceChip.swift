import EntropyCore
import SwiftUI

// MARK: - Constants

private enum Constants {
    static let chipWidth: CGFloat = 180
    static let thumbnailSize: CGFloat = 48

    static var articleAccessibilityLabel: String {
        AppLocalization.localized("article_row.accessibility_label")
    }

    static var readArticleHint: String {
        AppLocalization.localized("accessibility.read_article")
    }
}

// MARK: - InlineSourceChip

struct InlineSourceChip: View {
    let article: FeedSourceArticle
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.sm) {
                thumbnailView

                VStack(alignment: .leading, spacing: 2) {
                    Text(article.title)
                        .font(Typography.captionLarge)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: Spacing.xxs) {
                        Text(article.source)
                            .font(Typography.captionSmall)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        Text("•")
                            .font(Typography.captionSmall)
                            .foregroundStyle(.secondary.opacity(0.5))
                            .accessibilityHidden(true)

                        Text(article.formattedDate)
                            .font(Typography.captionSmall)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: Constants.chipWidth, alignment: .leading)
            .padding(Spacing.xs)
            .glassBackground(style: .ultraThin, cornerRadius: CornerRadius.sm)
        }
        .buttonStyle(.plain)
        .pressEffect(scale: 0.95)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(format: Constants.articleAccessibilityLabel, article.title, article.source, article.formattedDate))
        .accessibilityHint(Constants.readArticleHint)
    }

    // MARK: - Thumbnail

    @ViewBuilder
    private var thumbnailView: some View {
        if let imageURL = article.imageURL, let url = URL(string: imageURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    placeholderImage
                case let .success(image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    placeholderImage
                @unknown default:
                    placeholderImage
                }
            }
            .frame(width: Constants.thumbnailSize, height: Constants.thumbnailSize)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xs))
        } else {
            placeholderImage
        }
    }

    private var placeholderImage: some View {
        RoundedRectangle(cornerRadius: CornerRadius.xs)
            .fill(Color.secondary.opacity(0.2))
            .frame(width: Constants.thumbnailSize, height: Constants.thumbnailSize)
            .overlay {
                Image(systemName: "newspaper")
                    .font(.system(size: IconSize.sm))
                    .foregroundStyle(.secondary)
            }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Spacing.md) {
        InlineSourceChip(
            article: FeedSourceArticle(from: Article.mockArticles[0]),
            onTap: {}
        )

        InlineSourceChip(
            article: FeedSourceArticle(from: Article.mockArticles[1]),
            onTap: {}
        )
    }
    .padding()
    .background(LinearGradient.subtleBackground)
    .preferredColorScheme(.dark)
}
