import EntropyCore
import SwiftUI

// MARK: - Constants

private enum Constants {
    static let featuredImageHeight: CGFloat = 140
    static let featuredImageCornerRadius: CGFloat = 12
}

// MARK: - ContentSectionCard

struct ContentSectionCard: View {
    let section: DigestSection
    let onArticleTapped: (FeedSourceArticle) -> Void

    private var featuredArticle: FeedSourceArticle? {
        section.relatedArticles.first
    }

    private var remainingArticles: [FeedSourceArticle] {
        Array(section.relatedArticles.dropFirst())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            header

            sectionContent

            if let featured = featuredArticle {
                featuredArticleView(featured)
            }

            if !remainingArticles.isEmpty {
                sourcesRow
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(categoryTintBackground)
        .glassBackground(style: .thin, cornerRadius: CornerRadius.lg, showBorder: false)
        .overlay(categoryBorder)
        .depthShadow(.medium)
    }

    // MARK: - Background

    private var categoryTintBackground: some View {
        let color = section.category?.color ?? Color.Accent.primary

        return LinearGradient(
            colors: [
                color.opacity(0.06),
                Color.clear,
                color.opacity(0.03),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Border

    private var categoryBorder: some View {
        let color = section.category?.color ?? Color.Accent.primary

        return RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [color.opacity(0.3), color.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 0.5
            )
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: Spacing.xs) {
            if let category = section.category {
                Image(systemName: category.icon)
                    .font(.system(size: IconSize.sm))
                    .foregroundStyle(category.color.gradient)
                    .accessibilityHidden(true)
            } else {
                Image(systemName: "doc.text")
                    .font(.system(size: IconSize.sm))
                    .foregroundStyle(Color.Accent.gradient)
                    .accessibilityHidden(true)
            }

            Text(section.title)
                .font(Typography.labelMedium)
                .foregroundStyle(.primary)
                .accessibilityAddTraits(.isHeader)

            Spacer()

            // Article count badge
            if !section.relatedArticles.isEmpty {
                articleCountBadge
            }
        }
    }

    private var articleCountBadge: some View {
        let count = section.relatedArticles.count
        let text = count == 1 ? AppLocalization.shared.localized("digest.article_count_one") : String(format: AppLocalization.shared.localized("digest.article_count_other"), count)

        return Text(text)
            .font(Typography.captionSmall)
            .foregroundStyle(.secondary)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, 2)
            .background(Color.secondary.opacity(0.1))
            .clipShape(Capsule())
    }

    // MARK: - Content

    private var sectionContent: some View {
        let paragraphs = section.content
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return VStack(alignment: .leading, spacing: Spacing.sm) {
            ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, paragraph in
                Text(paragraph)
                    .font(Typography.aiContentMedium)
                    .foregroundStyle(.primary.opacity(0.9))
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Featured Article

    private func featuredArticleView(_ article: FeedSourceArticle) -> some View {
        Button {
            HapticManager.shared.tap()
            onArticleTapped(article)
        } label: {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Featured image
                featuredImage(for: article)

                // Article info
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(article.title)
                        .font(Typography.titleSmall)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: Spacing.xs) {
                        Text(article.source)
                            .font(Typography.captionLarge)
                            .foregroundStyle(.secondary)

                        Text("•")
                            .font(Typography.captionLarge)
                            .foregroundStyle(.secondary.opacity(0.5))
                            .accessibilityHidden(true)

                        Text(article.formattedDate)
                            .font(Typography.captionLarge)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.sm)
            .glassBackground(style: .ultraThin, cornerRadius: CornerRadius.md)
        }
        .buttonStyle(.plain)
        .pressEffect(scale: 0.98)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(format: AppLocalization.shared.localized("article_row.accessibility_label"), article.title, article.source, article.formattedDate))
        .accessibilityHint(AppLocalization.shared.localized("accessibility.read_article"))
    }

    @ViewBuilder
    private func featuredImage(for article: FeedSourceArticle) -> some View {
        if let imageURL = article.imageURL, let url = URL(string: imageURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    featuredImagePlaceholder
                case let .success(image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: Constants.featuredImageHeight)
                        .clipShape(RoundedRectangle(cornerRadius: Constants.featuredImageCornerRadius))
                case .failure:
                    featuredImagePlaceholder
                @unknown default:
                    featuredImagePlaceholder
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: Constants.featuredImageHeight)
            .clipShape(RoundedRectangle(cornerRadius: Constants.featuredImageCornerRadius))
        } else {
            featuredImagePlaceholder
        }
    }

    private var featuredImagePlaceholder: some View {
        RoundedRectangle(cornerRadius: Constants.featuredImageCornerRadius)
            .fill(Color.secondary.opacity(0.1))
            .frame(height: Constants.featuredImageHeight)
            .overlay {
                Image(systemName: "newspaper.fill")
                    .font(.system(size: IconSize.xl))
                    .foregroundStyle(.secondary.opacity(0.3))
            }
    }

    // MARK: - Sources Row

    private var sourcesRow: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(AppLocalization.shared.localized("digest.related_articles"))
                .font(Typography.captionSmall)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.xs) {
                    ForEach(remainingArticles) { article in
                        InlineSourceChip(article: article) {
                            HapticManager.shared.tap()
                            onArticleTapped(article)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    // swiftlint:disable:next line_length
    let content = "The technology sector saw significant developments this week with major AI announcements from leading tech companies. New breakthrough models promise enhanced capabilities across various domains."
    let previewSection = DigestSection(
        title: "Technology",
        content: content,
        category: .technology,
        relatedArticles: [
            FeedSourceArticle(from: Article.mockArticles[0]),
            FeedSourceArticle(from: Article.mockArticles[1]),
            FeedSourceArticle(from: Article.mockArticles[2]),
        ]
    )

    return ScrollView {
        ContentSectionCard(
            section: previewSection,
            onArticleTapped: { _ in }
        )
        .padding()
    }
    .background(LinearGradient.subtleBackground)
    .preferredColorScheme(.dark)
}
