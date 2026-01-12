import EntropyCore
import SwiftUI

struct CollectionDetailView<R: CollectionsNavigationRouter>: View {
    let collection: Collection
    private var router: R
    let serviceLocator: ServiceLocator

    @State private var selectedArticle: Article?

    init(collection: Collection, router: R, serviceLocator: ServiceLocator) {
        self.collection = collection
        self.router = router
        self.serviceLocator = serviceLocator
    }

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: 0) {
                    headerSection

                    articlesList
                }
            }
        }
        .navigationTitle(collection.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onChange(of: selectedArticle) { _, newValue in
            if let article = newValue {
                router.route(navigationEvent: .articleDetail(article))
                selectedArticle = nil
            }
        }
    }

    private var backgroundGradient: some View {
        LinearGradient.subtleBackground
    }

    private var headerSection: some View {
        GlassCard(style: .thin, shadowStyle: .medium, padding: Spacing.lg) {
            VStack(spacing: Spacing.md) {
                HStack {
                    iconView

                    Spacer()

                    if collection.isPremium {
                        PremiumBadge()
                    }

                    if collection.isCompleted {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.Semantic.success)
                            Text("Completed")
                                .font(Typography.labelMedium)
                                .foregroundStyle(Color.Semantic.success)
                        }
                    }
                }

                Text(collection.description)
                    .font(Typography.bodyMedium)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                progressView

                if let nextArticle = collection.nextUnreadArticle {
                    continueReadingButton(nextArticle)
                }
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.sm)
    }

    private var iconView: some View {
        ZStack {
            Circle()
                .fill(iconBackgroundColor)
                .frame(width: 56, height: 56)

            Image(systemName: iconName)
                .font(.system(size: IconSize.lg))
                .foregroundStyle(iconColor)
        }
    }

    private var progressView: some View {
        VStack(spacing: Spacing.xs) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: CornerRadius.xs)
                        .fill(Color.Semantic.skeleton)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: CornerRadius.xs)
                        .fill(progressColor)
                        .frame(width: geometry.size.width * collection.progress, height: 8)
                }
            }
            .frame(height: 8)

            HStack {
                Text("\(collection.readArticleIDs.count) of \(collection.articleCount) articles read")
                    .font(Typography.captionLarge)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(Int(collection.progress * 100))%")
                    .font(Typography.labelMedium)
                    .foregroundStyle(progressColor)
            }
        }
    }

    private func continueReadingButton(_ article: Article) -> some View {
        Button {
            HapticManager.shared.tap()
            selectedArticle = article
        } label: {
            HStack {
                Image(systemName: "play.fill")
                Text("Continue Reading")
            }
            .font(Typography.labelLarge)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .background(Color.Accent.primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .pressEffect()
    }

    private var articlesList: some View {
        VStack(spacing: 0) {
            ForEach(Array(collection.articles.enumerated()), id: \.element.id) { index, article in
                CollectionArticleRow(
                    article: article,
                    index: index + 1,
                    isRead: collection.readArticleIDs.contains(article.id),
                    isNext: article.id == collection.nextUnreadArticle?.id
                ) {
                    selectedArticle = article
                }

                if index < collection.articles.count - 1 {
                    Divider()
                        .padding(.leading, 60)
                        .padding(.horizontal, Spacing.md)
                }
            }
        }
        .padding(.top, Spacing.md)
    }

    private var iconName: String {
        if let definition = CollectionDefinition.all.first(where: { $0.id == collection.id }) {
            return definition.iconName
        }
        return "folder.fill"
    }

    private var iconBackgroundColor: Color {
        switch collection.collectionType {
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
        switch collection.collectionType {
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
        if collection.isCompleted {
            return Color.Semantic.success
        }
        return Color.Accent.primary
    }
}

struct CollectionArticleRow: View {
    let article: Article
    let index: Int
    let isRead: Bool
    let isNext: Bool
    let onTap: () -> Void

    var body: some View {
        Button {
            HapticManager.shared.tap()
            onTap()
        } label: {
            HStack(spacing: Spacing.md) {
                indexIndicator

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(article.title)
                        .font(Typography.titleSmall)
                        .foregroundStyle(isRead ? .secondary : .primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: Spacing.xs) {
                        Text(article.source.name)
                            .font(Typography.captionLarge)
                            .foregroundStyle(.tertiary)

                        Text("·")
                            .foregroundStyle(.tertiary)

                        Text(article.formattedDate)
                            .font(Typography.captionLarge)
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer()

                if isNext {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: IconSize.md))
                        .foregroundStyle(Color.Accent.primary)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var indexIndicator: some View {
        ZStack {
            Circle()
                .fill(circleColor)
                .frame(width: 32, height: 32)

            if isRead {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            } else {
                Text("\(index)")
                    .font(Typography.labelMedium)
                    .foregroundStyle(isNext ? .white : .secondary)
            }
        }
    }

    private var circleColor: Color {
        if isRead {
            return Color.Semantic.success
        } else if isNext {
            return Color.Accent.primary
        }
        return Color.Semantic.skeleton
    }
}

#Preview {
    NavigationStack {
        CollectionDetailView(
            collection: Collection(
                id: "1",
                name: "Climate Crisis",
                description: "Understand the science, politics, and solutions to our planet's greatest challenge",
                imageURL: nil,
                articles: Article.samples,
                articleCount: 5,
                readArticleIDs: ["1", "2"],
                collectionType: .featured,
                isPremium: false,
                createdAt: Date(),
                updatedAt: Date()
            ),
            router: CollectionsNavigationRouter(),
            serviceLocator: .preview
        )
    }
}
