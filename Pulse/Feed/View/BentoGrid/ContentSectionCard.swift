import EntropyCore
import SwiftUI

// MARK: - ContentSectionCard

struct ContentSectionCard: View {
    let section: DigestSection
    let onArticleTapped: (FeedSourceArticle) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            header

            sectionContent

            if !section.relatedArticles.isEmpty {
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
            } else {
                Image(systemName: "doc.text")
                    .font(.system(size: IconSize.sm))
                    .foregroundStyle(Color.Accent.gradient)
            }

            Text(section.title)
                .font(Typography.labelMedium)
                .foregroundStyle(.primary)
        }
    }

    // MARK: - Content

    private var sectionContent: some View {
        Text(section.content)
            .font(Typography.aiContentMedium)
            .foregroundStyle(.primary.opacity(0.9))
            .lineSpacing(4)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Sources Row

    private var sourcesRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                ForEach(section.relatedArticles) { article in
                    InlineSourceChip(article: article) {
                        HapticManager.shared.tap()
                        onArticleTapped(article)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let previewSection = DigestSection(
        title: "Technology",
        content: "The technology sector saw significant developments with new AI models.",
        category: .technology,
        relatedArticles: [
            FeedSourceArticle(from: Article.mockArticles[0]),
            FeedSourceArticle(from: Article.mockArticles[1]),
        ]
    )

    return ContentSectionCard(
        section: previewSection,
        onArticleTapped: { _ in }
    )
    .padding()
    .background(LinearGradient.subtleBackground)
}
