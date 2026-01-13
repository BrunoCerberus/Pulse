import SwiftUI

// MARK: - Constants

private enum Constants {
    static let sectionTitle = "Source Articles"
}

// MARK: - SourceArticlesSection

struct SourceArticlesSection: View {
    let articles: [FeedSourceArticle]
    let onArticleTapped: (FeedSourceArticle) -> Void

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader

            if isExpanded {
                articlesList
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isExpanded)
    }

    // MARK: - Section Header

    private var sectionHeader: some View {
        Button {
            HapticManager.shared.tap()
            isExpanded.toggle()
        } label: {
            HStack {
                Text(Constants.sectionTitle)
                    .font(Typography.titleSmall)
                    .foregroundStyle(.primary)

                Text("(\(articles.count))")
                    .font(Typography.captionLarge)
                    .foregroundStyle(.secondary)

                Spacer()

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: IconSize.sm))
                    .foregroundStyle(.secondary)
            }
            .padding(Spacing.md)
            .glassBackground(style: .ultraThin, cornerRadius: CornerRadius.md)
        }
        .buttonStyle(.plain)
        .pressEffect()
    }

    // MARK: - Articles List

    private var articlesList: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(articles) { article in
                SourceArticleRow(article: article) {
                    onArticleTapped(article)
                }
            }
        }
    }
}

// MARK: - SourceArticleRow

private struct SourceArticleRow: View {
    let article: FeedSourceArticle
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.md) {
                thumbnailView

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(article.title)
                        .font(Typography.labelMedium)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: Spacing.xs) {
                        Text(article.source)
                            .font(Typography.captionLarge)
                            .foregroundStyle(.secondary)

                        if let category = article.category {
                            Circle()
                                .fill(.secondary)
                                .frame(width: 3, height: 3)

                            Text(category)
                                .font(Typography.captionLarge)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: IconSize.xs))
                    .foregroundStyle(.tertiary)
            }
            .padding(Spacing.md)
            .glassBackground(style: .ultraThin, cornerRadius: CornerRadius.md)
        }
        .buttonStyle(.plain)
        .pressEffect()
    }

    // MARK: - Thumbnail View

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
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
        } else {
            placeholderImage
        }
    }

    private var placeholderImage: some View {
        RoundedRectangle(cornerRadius: CornerRadius.sm)
            .fill(Color.secondary.opacity(0.2))
            .frame(width: 60, height: 60)
            .overlay {
                Image(systemName: "newspaper")
                    .font(.system(size: IconSize.md))
                    .foregroundStyle(.secondary)
            }
    }
}

#Preview {
    SourceArticlesSection(
        articles: [
            FeedSourceArticle(from: Article.mockArticles[0]),
            FeedSourceArticle(from: Article.mockArticles[1]),
        ],
        onArticleTapped: { _ in }
    )
    .padding()
}
