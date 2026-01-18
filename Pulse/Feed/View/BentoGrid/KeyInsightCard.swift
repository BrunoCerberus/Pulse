import SwiftUI

// MARK: - Constants

private enum Constants {
    static let headerTitle = "Key Insight"
}

// MARK: - KeyInsightCard

struct KeyInsightCard: View {
    let insight: String
    let relatedArticles: [FeedSourceArticle]
    let onArticleTapped: (FeedSourceArticle) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            header

            insightContent

            if !relatedArticles.isEmpty {
                sourcesRow
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(gradientBackground)
        .glassBackground(style: .thin, cornerRadius: CornerRadius.lg, showBorder: false)
        .overlay(accentBorder)
        .depthShadow(.elevated)
    }

    // MARK: - Background

    private var gradientBackground: some View {
        Group {
            if #available(iOS 18.0, *) {
                meshGradientBackground
            } else {
                fallbackGradientBackground
            }
        }
    }

    @available(iOS 18.0, *)
    private var meshGradientBackground: some View {
        MeshGradient.glassMesh
            .opacity(0.6)
    }

    private var fallbackGradientBackground: some View {
        LinearGradient(
            colors: [
                Color.Accent.primary.opacity(0.08),
                Color.Accent.secondary.opacity(0.05),
                Color.clear,
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Border

    private var accentBorder: some View {
        RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [
                        Color.Accent.primary.opacity(0.4),
                        Color.Accent.secondary.opacity(0.2),
                        Color.Accent.primary.opacity(0.1),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "sparkles")
                .font(.system(size: IconSize.md))
                .foregroundStyle(Color.Accent.gradient)
                .symbolEffect(
                    .pulse.byLayer,
                    options: reduceMotion ? .repeat(1) : .repeat(.periodic(delay: 2.0))
                )

            Text(Constants.headerTitle)
                .font(Typography.labelMedium)
                .foregroundStyle(Color.Accent.primary)
        }
    }

    // MARK: - Insight Content

    private var insightContent: some View {
        HStack(alignment: .top, spacing: 0) {
            // Left accent border
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.Accent.gradient)
                .frame(width: 3)
                .padding(.trailing, Spacing.md)

            // Content with drop cap
            dropCapText
        }
    }

    private var dropCapText: some View {
        let trimmedInsight = insight.trimmingCharacters(in: .whitespacesAndNewlines)
        let firstChar = trimmedInsight.isEmpty ? "" : String(trimmedInsight.prefix(1))
        let remainingText = trimmedInsight.isEmpty ? "" : String(trimmedInsight.dropFirst())

        return HStack(alignment: .top, spacing: 0) {
            // Drop cap
            Text(firstChar)
                .font(Typography.aiDropCap)
                .foregroundStyle(Color.Accent.primary)
                .frame(width: 44, alignment: .leading)
                .padding(.trailing, Spacing.xs)
                .accessibilityHidden(true)

            // Remaining text
            Text(remainingText)
                .font(Typography.aiContentMedium)
                .foregroundStyle(.primary.opacity(0.9))
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(trimmedInsight)
    }

    // MARK: - Sources Row

    private var sourcesRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                ForEach(relatedArticles.prefix(3)) { article in
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
    let previewInsight = """
    Today's reading focused on technology and business developments, with AI advancements \
    taking center stage in the tech world.
    """

    return KeyInsightCard(
        insight: previewInsight,
        relatedArticles: [
            FeedSourceArticle(from: Article.mockArticles[0]),
            FeedSourceArticle(from: Article.mockArticles[1]),
        ],
        onArticleTapped: { _ in }
    )
    .padding()
    .background(LinearGradient.subtleBackground)
}
