import EntropyCore
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

            summaryContent
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(gradientOverlay)
        .glassBackground(style: .thin, cornerRadius: CornerRadius.lg, showBorder: false)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.Accent.primary.opacity(0.3), Color.Accent.primary.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    // MARK: - Gradient Overlay

    private var gradientOverlay: some View {
        LinearGradient(
            colors: [
                Color.Accent.primary.opacity(0.05),
                Color.clear,
                Color.Accent.primary.opacity(0.03),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
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

    // MARK: - Summary Content

    private var summaryContent: some View {
        HStack(alignment: .top, spacing: 0) {
            // Left accent border
            RoundedRectangle(cornerRadius: 2)
                .fill(
                    LinearGradient(
                        colors: [Color.Accent.primary, Color.Accent.primary.opacity(0.5)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 3)
                .padding(.trailing, Spacing.md)

            // Content with drop cap
            dropCapText
        }
    }

    // MARK: - Drop Cap Text

    private var dropCapText: some View {
        let summary = digest.summary.trimmingCharacters(in: .whitespacesAndNewlines)
        let firstChar = summary.isEmpty ? "" : String(summary.prefix(1))
        let remainingText = summary.isEmpty ? "" : String(summary.dropFirst())

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
        .accessibilityLabel(summary)
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
    .preferredColorScheme(.dark)
}
