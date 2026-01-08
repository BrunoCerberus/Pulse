import SwiftUI

// MARK: - Constants

private enum Constants {
    static let back = String(localized: "common.back")
    static let readFull = String(localized: "article.read_full")
    static let aiSummary = String(localized: "summarization.ai_summary")
    static let generatedOn = String(localized: "summarization.generated_on")
}

// MARK: - SummaryDetailView

/// Displays an AI-generated summary of an article with header information.
struct SummaryDetailView: View {
    let summaryItem: SummaryItem
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL
    private let heroBaseHeight: CGFloat = 280

    var body: some View {
        ZStack(alignment: .top) {
            LinearGradient.subtleBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if let imageURL = summaryItem.article.imageURL, let url = URL(string: imageURL) {
                        StretchyAsyncImage(
                            url: url,
                            baseHeight: heroBaseHeight,
                            accessibilityLabel: summaryItem.article.title
                        )
                    }

                    contentCard
                }
            }
            .accessibilityIdentifier("summaryDetailScrollView")
        }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Label(Constants.back, systemImage: "chevron.left")
                        .labelStyle(.iconOnly)
                }
                .accessibilityIdentifier("backButton")
                .accessibilityLabel(Constants.back)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("", systemImage: "square.and.arrow.up") {
                    shareArticle()
                }
                .accessibilityIdentifier("shareButton")
                .accessibilityLabel("Share article")
            }
        }
        .enableSwipeBack()
    }

    private var contentCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            if let category = summaryItem.article.category {
                GlassCategoryChip(category: category, style: .medium, showIcon: true)
                    .glowEffect(color: category.color, radius: 6)
            }

            Text(summaryItem.article.title)
                .font(Typography.displaySmall)

            metadataRow

            Rectangle()
                .fill(Color.Border.adaptive(for: colorScheme))
                .frame(height: 0.5)

            // AI Summary Badge
            aiBadge

            // Summary Content
            Text(summaryItem.summary)
                .font(Typography.bodyLarge)
                .foregroundStyle(.primary.opacity(0.9))
                .lineSpacing(8)
                .padding(.leading, Spacing.md)
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(Color.Accent.gradient)
                        .frame(width: 3)
                        .clipShape(RoundedRectangle(cornerRadius: 1.5))
                }

            // Generation timestamp
            Text("\(Constants.generatedOn) \(summaryItem.generatedAt.formatted(date: .abbreviated, time: .shortened))")
                .font(Typography.captionSmall)
                .foregroundStyle(.tertiary)

            Rectangle()
                .fill(Color.Border.adaptive(for: colorScheme))
                .frame(height: 0.5)

            readFullArticleButton
        }
        .padding(Spacing.lg)
        .background(.regularMaterial)
        .clipShape(
            .rect(
                topLeadingRadius: CornerRadius.xl,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: CornerRadius.xl
            )
        )
        .offset(y: -Spacing.lg)
    }

    private var aiBadge: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "sparkles")
                .font(.system(size: IconSize.sm))
            Text(Constants.aiSummary)
                .font(Typography.labelMedium)
        }
        .foregroundStyle(Color.Accent.primary)
        .padding(.vertical, Spacing.xs)
    }

    private var metadataRow: some View {
        HStack(spacing: Spacing.xs) {
            if let author = summaryItem.article.author {
                Text("By \(author)")
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .layoutPriority(-1)

                Circle()
                    .fill(.secondary)
                    .frame(width: 3, height: 3)
            }

            Text(summaryItem.article.source.name)
                .lineLimit(1)

            Circle()
                .fill(.secondary)
                .frame(width: 3, height: 3)

            Text(summaryItem.article.formattedDate)
                .lineLimit(1)
                .layoutPriority(1)
        }
        .font(Typography.captionLarge)
        .foregroundStyle(.secondary)
    }

    private var readFullArticleButton: some View {
        Button {
            HapticManager.shared.buttonPress()
            openInBrowser()
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "safari.fill")
                Text(Constants.readFull)
            }
            .font(Typography.labelLarge)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(Color.Accent.gradient)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
        }
        .pressEffect()
    }

    private func openInBrowser() {
        guard let url = URL(string: summaryItem.article.url) else { return }
        openURL(url)
    }

    private func shareArticle() {
        guard let url = URL(string: summaryItem.article.url) else { return }
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController
        {
            rootVC.present(activityVC, animated: true)
        }
    }
}

#Preview {
    NavigationStack {
        SummaryDetailView(
            summaryItem: SummaryItem(
                article: Article.mockArticles[0],
                summary: """
                This is an AI-generated summary of the article. It highlights the key points \
                and main takeaways from the content, providing a quick overview for readers \
                who want to understand the essence of the article without reading the full text.
                """,
                generatedAt: Date()
            )
        )
    }
}
