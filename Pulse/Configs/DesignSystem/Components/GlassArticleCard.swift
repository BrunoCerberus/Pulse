import SwiftUI

// MARK: - Glass Article Card

struct GlassArticleCard: View {
    let title: String
    let description: String?
    let sourceName: String
    let formattedDate: String
    let imageURL: URL?
    let category: NewsCategory?
    let isBookmarked: Bool
    let onTap: () -> Void
    let onBookmark: () -> Void
    let onShare: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    init(
        title: String,
        description: String? = nil,
        sourceName: String,
        formattedDate: String,
        imageURL: URL? = nil,
        category: NewsCategory? = nil,
        isBookmarked: Bool = false,
        onTap: @escaping () -> Void,
        onBookmark: @escaping () -> Void,
        onShare: @escaping () -> Void
    ) {
        self.title = title
        self.description = description
        self.sourceName = sourceName
        self.formattedDate = formattedDate
        self.imageURL = imageURL
        self.category = category
        self.isBookmarked = isBookmarked
        self.onTap = onTap
        self.onBookmark = onBookmark
        self.onShare = onShare
    }

    var body: some View {
        Button {
            HapticManager.shared.tap()
            onTap()
        } label: {
            HStack(alignment: .top, spacing: Spacing.sm) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    if let category {
                        GlassCategoryChip(category: category, style: .small)
                    }

                    Text(title)
                        .font(Typography.headlineMedium)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.primary)

                    if let description {
                        Text(description)
                            .font(Typography.bodySmall)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    HStack(spacing: Spacing.xs) {
                        Text(sourceName)
                            .font(Typography.captionLarge)
                            .fontWeight(.medium)

                        Circle()
                            .fill(.secondary)
                            .frame(width: 3, height: 3)

                        Text(formattedDate)
                            .font(Typography.captionLarge)
                    }
                    .foregroundStyle(.secondary)
                }

                Spacer(minLength: Spacing.xs)

                articleImage
            }
            .padding(Spacing.md)
            .glassBackground(style: .solid, cornerRadius: CornerRadius.lg)
            .depthShadow(.subtle)
        }
        .pressEffect()
        .contextMenu {
            Button {
                onBookmark()
            } label: {
                Label(
                    isBookmarked ? "Remove Bookmark" : "Bookmark",
                    systemImage: isBookmarked ? "bookmark.fill" : "bookmark"
                )
            }

            Button {
                onShare()
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        }
    }

    @ViewBuilder
    private var articleImage: some View {
        if let imageURL {
            CachedAsyncImage(url: imageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipped()
            } placeholder: {
                imagePlaceholder
                    .overlay {
                        ProgressView()
                            .tint(.secondary)
                    }
            }
            .frame(width: 100, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous)
                    .stroke(Color.Border.adaptive(for: colorScheme), lineWidth: 0.5)
            )
        }
    }

    private var imagePlaceholder: some View {
        RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous)
            .fill(Color.primary.opacity(0.05))
            .frame(width: 100, height: 100)
    }
}

// MARK: - Convenience Init with ArticleViewItem

extension GlassArticleCard {
    init(
        item: ArticleViewItem,
        isBookmarked: Bool = false,
        onTap: @escaping () -> Void,
        onBookmark: @escaping () -> Void,
        onShare: @escaping () -> Void
    ) {
        self.init(
            title: item.title,
            description: item.description,
            sourceName: item.sourceName,
            formattedDate: item.formattedDate,
            imageURL: item.imageURL,
            category: item.category,
            isBookmarked: isBookmarked,
            onTap: onTap,
            onBookmark: onBookmark,
            onShare: onShare
        )
    }
}

// MARK: - Compact Variant

struct GlassArticleCardCompact: View {
    let title: String
    let sourceName: String
    let imageURL: URL?
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button {
            HapticManager.shared.tap()
            onTap()
        } label: {
            HStack(spacing: Spacing.sm) {
                if let imageURL {
                    CachedAsyncImage(url: imageURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.primary.opacity(0.05)
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous))
                }

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(title)
                        .font(Typography.headlineSmall)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.primary)

                    Text(sourceName)
                        .font(Typography.captionMedium)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }
            .padding(Spacing.sm)
            .glassBackground(style: .solid, cornerRadius: CornerRadius.md)
        }
        .pressEffect()
    }
}

// MARK: - Previews

#Preview("Glass Article Card") {
    ZStack {
        LinearGradient.meshFallback
            .ignoresSafeArea()

        ScrollView {
            VStack(spacing: Spacing.md) {
                GlassArticleCard(
                    title: "Apple Announces Revolutionary New AI Features for iPhone",
                    description: """
                    The tech giant unveiled groundbreaking artificial intelligence \
                    capabilities that will transform how users interact with their devices.
                    """,
                    sourceName: "TechCrunch",
                    formattedDate: "2h ago",
                    imageURL: URL(string: "https://picsum.photos/200"),
                    category: .technology,
                    isBookmarked: false,
                    onTap: {},
                    onBookmark: {},
                    onShare: {}
                )

                GlassArticleCard(
                    title: "Breaking: Major Climate Agreement Reached",
                    description: nil,
                    sourceName: "Reuters",
                    formattedDate: "30m ago",
                    imageURL: nil,
                    category: .world,
                    isBookmarked: true,
                    onTap: {},
                    onBookmark: {},
                    onShare: {}
                )

                GlassArticleCardCompact(
                    title: "Quick Update on Markets",
                    sourceName: "Bloomberg",
                    imageURL: URL(string: "https://picsum.photos/100"),
                    onTap: {}
                )
            }
            .padding()
        }
    }
}
