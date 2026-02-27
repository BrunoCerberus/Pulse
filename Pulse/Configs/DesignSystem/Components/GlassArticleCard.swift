import EntropyCore
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
    let isRead: Bool
    let onTap: () -> Void
    let onBookmark: () -> Void
    let onShare: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var imageSize: CGFloat = 100

    init(
        title: String,
        description: String? = nil,
        sourceName: String,
        formattedDate: String,
        imageURL: URL? = nil,
        category: NewsCategory? = nil,
        isBookmarked: Bool = false,
        isRead: Bool = false,
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
        self.isRead = isRead
        self.onTap = onTap
        self.onBookmark = onBookmark
        self.onShare = onShare
    }

    var body: some View {
        Button {
            HapticManager.shared.tap()
            onTap()
        } label: {
            cardContent
                .padding(Spacing.md)
                .glassBackground(style: .solid, cornerRadius: CornerRadius.lg)
                .depthShadow(.subtle)
        }
        .pressEffect()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(format: AppLocalization.localized("article_row.accessibility_label"), title, sourceName, formattedDate))
        .accessibilityHint(AppLocalization.localized("accessibility.read_article"))
        .accessibilityIdentifier("articleCard")
        .contextMenu {
            Button {
                onBookmark()
            } label: {
                Label(
                    isBookmarked ? AppLocalization.localized("article.remove_bookmark") : AppLocalization.localized("article.bookmark"),
                    systemImage: isBookmarked ? "bookmark.fill" : "bookmark"
                )
            }

            Button {
                onShare()
            } label: {
                Label(AppLocalization.localized("article.share"), systemImage: "square.and.arrow.up")
            }
        }
    }

    @ViewBuilder
    private var cardContent: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                articleImage
                textContent
            }
        } else {
            HStack(alignment: .top, spacing: Spacing.sm) {
                textContent
                Spacer(minLength: Spacing.xs)
                articleImage
            }
        }
    }

    private var textContent: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            if let category {
                GlassCategoryChip(category: category, style: .small)
            }

            Text(title)
                .font(Typography.headlineMedium)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 5 : 3)
                .multilineTextAlignment(.leading)
                .foregroundStyle(.primary)
                .opacity(isRead ? 0.55 : 1.0)

            if let description {
                Text(description)
                    .font(Typography.bodySmall)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .opacity(isRead ? 0.45 : 1.0)
            }

            HStack(spacing: Spacing.xs) {
                Text(sourceName)
                    .font(Typography.captionLarge)
                    .fontWeight(.medium)

                Circle()
                    .fill(.secondary)
                    .frame(width: 3, height: 3)
                    .accessibilityHidden(true)

                Text(formattedDate)
                    .font(Typography.captionLarge)
            }
            .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var articleImage: some View {
        if let imageURL {
            if dynamicTypeSize.isAccessibilitySize {
                CachedAsyncImage(url: imageURL, accessibilityLabel: title) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .frame(height: 150)
                        .clipped()
                } placeholder: {
                    RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous)
                        .fill(Color.primary.opacity(0.05))
                        .frame(maxWidth: .infinity)
                        .frame(height: 150)
                        .overlay {
                            ProgressView()
                                .tint(.secondary)
                        }
                }
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous)
                        .stroke(Color.Border.adaptive(for: colorScheme), lineWidth: 0.5)
                )
                .opacity(isRead ? 0.7 : 1.0)
            } else {
                CachedAsyncImage(url: imageURL, accessibilityLabel: title) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: imageSize, height: imageSize)
                        .clipped()
                } placeholder: {
                    imagePlaceholder
                        .overlay {
                            ProgressView()
                                .tint(.secondary)
                        }
                }
                .frame(width: imageSize, height: imageSize)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous)
                        .stroke(Color.Border.adaptive(for: colorScheme), lineWidth: 0.5)
                )
                .opacity(isRead ? 0.7 : 1.0)
            }
        }
    }

    private var imagePlaceholder: some View {
        RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous)
            .fill(Color.primary.opacity(0.05))
            .frame(width: imageSize, height: imageSize)
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
            isRead: item.isRead,
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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var imageSize: CGFloat = 60

    var body: some View {
        Button {
            HapticManager.shared.tap()
            onTap()
        } label: {
            HStack(spacing: Spacing.sm) {
                if let imageURL {
                    CachedAsyncImage(url: imageURL, accessibilityLabel: title) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.primary.opacity(0.05)
                    }
                    .frame(width: imageSize, height: imageSize)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous))
                }

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(title)
                        .font(Typography.headlineSmall)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? 4 : 2)
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(format: AppLocalization.localized("article_row.accessibility_label"), title, sourceName, ""))
        .accessibilityHint(AppLocalization.localized("accessibility.read_article"))
        .accessibilityIdentifier("articleCard")
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
    .preferredColorScheme(.dark)
}
