import SwiftUI

// MARK: - ArticleDetailView Subviews

extension ArticleDetailView {
    private var contentCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            if let category = viewModel.viewState.article.category {
                GlassCategoryChip(category: category, style: .medium, showIcon: true)
                    .glowEffect(color: category.color, radius: 6)
            }

            Text(viewModel.viewState.article.title)
                .font(Typography.titleLarge)
                .fontWeight(.bold)
                .accessibilityAddTraits(.isHeader)

            metadataRow

            Rectangle()
                .fill(Color.Border.adaptive(for: colorScheme))
                .frame(height: 0.5)

            if let description = viewModel.viewState.processedDescription {
                Text(description)
                    .foregroundStyle(.primary.opacity(0.9))
                    .lineSpacing(8)
                    .padding(.leading, Spacing.md)
                    .padding(.vertical, Spacing.xs)
                    .overlay(alignment: .leading) {
                        Rectangle()
                            .fill(Color.Accent.gradient)
                            .frame(width: 3)
                            .clipShape(RoundedRectangle(cornerRadius: 1.5))
                    }
            }

            if let content = viewModel.viewState.processedContent {
                Text(content)
                    .foregroundStyle(.primary.opacity(0.85))
                    .lineSpacing(6)
            }

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

    @ViewBuilder
    private var metadataRow: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                if let author = viewModel.viewState.article.author {
                    Text(String(format: AppLocalization.shared.localized("article.by_author"), author))
                        .fontWeight(.medium)
                }

                Text(viewModel.viewState.article.source.name)

                Text(viewModel.viewState.article.formattedDate)
            }
            .font(Typography.captionLarge)
            .foregroundStyle(.secondary)
        } else {
            HStack(spacing: Spacing.xs) {
                if let author = viewModel.viewState.article.author {
                    Text(String(format: AppLocalization.shared.localized("article.by_author"), author))
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .layoutPriority(-1)

                    Circle()
                        .fill(.secondary)
                        .frame(width: 3, height: 3)
                        .accessibilityHidden(true)
                }

                Text(viewModel.viewState.article.source.name)
                    .lineLimit(1)

                Circle()
                    .fill(.secondary)
                    .frame(width: 3, height: 3)
                    .accessibilityHidden(true)

                Text(viewModel.viewState.article.formattedDate)
                    .lineLimit(1)
                    .layoutPriority(1)
            }
            .font(Typography.captionLarge)
            .foregroundStyle(.secondary)
        }
    }

    private var readFullArticleButton: some View {
        Button {
            HapticManager.shared.buttonPress()
            viewModel.handle(event: .onReadFullTapped)
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
        .accessibilityHint(AppLocalization.shared.localized("accessibility.opens_in_safari"))
    }
}
