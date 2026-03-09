import EntropyCore
import SwiftUI

/// Compact card displaying a story thread in the list.
struct StoryThreadCardView: View {
    let item: StoryThreadItem
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                headerRow
                summaryText
                footerRow
            }
            .padding(Spacing.md)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                    .stroke(Color.Border.adaptive(for: colorScheme), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(AppLocalization.localized("story_threads.card_hint"))
    }

    private var headerRow: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(item.title)
                    .font(Typography.titleSmall)
                    .bold()
                    .lineLimit(2)
                    .accessibilityAddTraits(.isHeader)

                Text(item.category.capitalized)
                    .font(Typography.captionLarge)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if item.unreadCount > 0 {
                Text("\(item.unreadCount)")
                    .font(Typography.captionLarge)
                    .bold()
                    .foregroundStyle(.white)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xxs)
                    .background(Color.accentColor.gradient)
                    .clipShape(Capsule())
                    .accessibilityLabel(
                        String(format: AppLocalization.localized("story_threads.new_updates_count"), item.unreadCount)
                    )
            }
        }
    }

    private var summaryText: some View {
        Text(item.summary)
            .font(Typography.bodySmall)
            .foregroundStyle(.secondary)
            .lineLimit(2)
    }

    @ViewBuilder
    private var footerRow: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                footerContent
            }
        } else {
            HStack(spacing: Spacing.sm) {
                footerContent
            }
        }
    }

    @ViewBuilder
    private var footerContent: some View {
        Label(
            String(format: AppLocalization.localized("story_threads.article_count"), item.articleCount),
            systemImage: "doc.text"
        )
        .font(Typography.captionLarge)
        .foregroundStyle(.tertiary)

        if !dynamicTypeSize.isAccessibilitySize {
            Circle()
                .fill(.tertiary)
                .frame(width: 3, height: 3)
                .accessibilityHidden(true)
        }

        Label(item.lastUpdated, systemImage: "clock")
            .font(Typography.captionLarge)
            .foregroundStyle(.tertiary)
    }

    private var accessibilityLabel: String {
        var parts = [item.title, item.category.capitalized]
        parts.append(
            String(format: AppLocalization.localized("story_threads.article_count"), item.articleCount)
        )
        if item.unreadCount > 0 {
            parts.append(
                String(format: AppLocalization.localized("story_threads.new_updates_count"), item.unreadCount)
            )
        }
        parts.append(item.lastUpdated)
        return parts.joined(separator: ". ")
    }
}
