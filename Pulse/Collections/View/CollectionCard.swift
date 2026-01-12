import SwiftUI

struct CollectionCard: View {
    let item: CollectionViewItem
    let onTap: () -> Void

    var body: some View {
        Button {
            HapticManager.shared.tap()
            onTap()
        } label: {
            GlassCard(style: .thin, shadowStyle: .medium, padding: 0) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    headerSection

                    Text(item.name)
                        .font(Typography.titleSmall)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(item.description)
                        .font(Typography.captionLarge)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .frame(height: 32, alignment: .top)

                    Spacer(minLength: Spacing.xs)

                    progressSection
                }
                .padding(Spacing.md)
            }
            .frame(width: 180, height: 180)
        }
        .buttonStyle(.plain)
        .pressEffect()
    }

    private var headerSection: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(iconBackgroundColor)
                    .frame(width: 40, height: 40)

                Image(systemName: item.iconName)
                    .font(.system(size: IconSize.md))
                    .foregroundStyle(iconColor)
            }

            Spacer()

            if item.isPremium {
                PremiumBadge()
            }

            if item.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: IconSize.md))
                    .foregroundStyle(Color.Semantic.success)
            }
        }
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: CornerRadius.xs)
                        .fill(Color.Semantic.skeleton)
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: CornerRadius.xs)
                        .fill(progressColor)
                        .frame(width: geometry.size.width * item.progress, height: 4)
                }
            }
            .frame(height: 4)

            Text(item.progressText)
                .font(Typography.captionSmall)
                .foregroundStyle(.tertiary)
        }
    }

    private var iconBackgroundColor: Color {
        switch item.collectionType {
        case .featured:
            return Color.Accent.primary.opacity(0.15)
        case .topic:
            return Color.Accent.secondary.opacity(0.15)
        case .user:
            return Color.Semantic.info.opacity(0.15)
        case .aiCurated:
            return Color.Accent.gold.opacity(0.15)
        }
    }

    private var iconColor: Color {
        switch item.collectionType {
        case .featured:
            return Color.Accent.primary
        case .topic:
            return Color.Accent.secondary
        case .user:
            return Color.Semantic.info
        case .aiCurated:
            return Color.Accent.gold
        }
    }

    private var progressColor: Color {
        if item.isCompleted {
            return Color.Semantic.success
        }
        return Color.Accent.primary
    }
}

struct UserCollectionRow: View {
    let item: CollectionViewItem
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button {
            HapticManager.shared.tap()
            onTap()
        } label: {
            GlassCard(style: .ultraThin, shadowStyle: .subtle, padding: Spacing.md) {
                HStack(spacing: Spacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: CornerRadius.sm)
                            .fill(Color.Semantic.info.opacity(0.15))
                            .frame(width: 44, height: 44)

                        Image(systemName: item.iconName)
                            .font(.system(size: IconSize.md))
                            .foregroundStyle(Color.Semantic.info)
                    }

                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(item.name)
                            .font(Typography.titleSmall)
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Text(item.progressText)
                            .font(Typography.captionLarge)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if item.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: IconSize.md))
                            .foregroundStyle(Color.Semantic.success)
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: IconSize.sm))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .buttonStyle(.plain)
        .pressEffect()
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

#Preview("Collection Card") {
    CollectionCard(
        item: CollectionViewItem(
            from: Collection(
                id: "1",
                name: "Climate Crisis",
                description: "Understand the science and solutions",
                imageURL: nil,
                articles: [],
                articleIDs: Set((1 ... 10).map { "\($0)" }),
                readArticleIDs: ["1", "2", "3"],
                collectionType: .featured,
                isPremium: false,
                createdAt: Date(),
                updatedAt: Date()
            )
        )
    ) {}
        .padding()
}

#Preview("User Collection Row") {
    UserCollectionRow(
        item: CollectionViewItem(
            from: Collection.userCollection(
                name: "My Research",
                description: "Articles for my project",
                articles: []
            )
        ),
        onTap: {},
        onDelete: {}
    )
    .padding()
}
