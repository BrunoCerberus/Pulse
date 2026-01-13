import SwiftUI

// MARK: - Constants

private enum Constants {
    static let aiSummary = "AI Summary"
    static let articlesLabel = "articles"
}

// MARK: - DigestCard

struct DigestCard: View {
    let digest: DigestViewItem

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            header

            Divider()
                .background(Color.Accent.primary.opacity(0.3))

            summaryText
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                .stroke(Color.Accent.primary.opacity(0.2), lineWidth: 1)
        )
        .glassBackground(style: .thin, cornerRadius: CornerRadius.lg)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "sparkles")
                .foregroundStyle(Color.Accent.primary)
                .symbolEffect(.pulse.byLayer, options: reduceMotion ? .repeat(1) : .repeat(.periodic(delay: 2.0)))

            Text(Constants.aiSummary)
                .font(Typography.labelMedium)
                .foregroundStyle(Color.Accent.primary)

            Spacer()

            HStack(spacing: Spacing.xxs) {
                Text("\(digest.articleCount)")
                    .font(Typography.labelSmall)
                    .foregroundStyle(.secondary)

                Text(Constants.articlesLabel)
                    .font(Typography.labelSmall)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xxs)
            .background(Color.secondary.opacity(0.1))
            .clipShape(Capsule())
        }
    }

    // MARK: - Summary Text

    private var summaryText: some View {
        Text(digest.summary)
            .font(Typography.bodyMedium)
            .foregroundStyle(.primary)
            .lineSpacing(4)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    let previewSummary = """
    Today's reading focused on technology and business. You explored developments in AI, \
    including new large language models and their applications in productivity tools. \
    The business articles covered market trends and startup funding rounds in the tech sector.
    """
    return DigestCard(
        digest: DigestViewItem(
            from: DailyDigest(
                id: "1",
                summary: previewSummary,
                sourceArticles: [],
                generatedAt: Date()
            )
        )
    )
    .padding()
}
