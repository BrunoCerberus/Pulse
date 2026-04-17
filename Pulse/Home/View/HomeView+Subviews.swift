import EntropyCore
import SwiftUI

// MARK: - HomeView Subviews Extension

/// Extracted subviews from HomeView to reduce type body length.
/// Contains loading states, error views, and utility views.
extension HomeView {
    // MARK: - Loading View

    var loadingView: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Category tabs at top of scrollable content
                if viewModel.viewState.showCategoryTabs {
                    categoryTabBar
                }

                // Only show breaking news skeleton when on "All" tab
                if viewModel.viewState.selectedCategory == nil {
                    GlassSectionHeader(Constants.breakingNews)
                    HeroCarouselSkeleton()
                }

                GlassSectionHeader(Constants.topHeadlines)
                ArticleListSkeleton(count: 5)
            }
        }
        .accessibilityHidden(true)
    }

    // MARK: - Error View

    func errorView(_ message: String) -> some View {
        GlassCard(style: .thin, shadowStyle: .medium, padding: Spacing.xl) {
            VStack(spacing: Spacing.md) {
                if viewModel.viewState.isOfflineError {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: IconSize.xxl))
                        .foregroundStyle(.orange)
                        .accessibilityHidden(true)

                    Text(Constants.offlineTitle)
                        .font(Typography.titleMedium)

                    Text(Constants.offlineMessage)
                        .font(Typography.bodyMedium)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: IconSize.xxl))
                        .foregroundStyle(Color.Semantic.warning)
                        .accessibilityHidden(true)

                    Text(Constants.errorTitle)
                        .font(Typography.titleMedium)

                    Text(message)
                        .font(Typography.bodyMedium)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button {
                        HapticManager.shared.tap()
                        viewModel.handle(event: .onRefresh)
                    } label: {
                        Text(Constants.tryAgain)
                            .font(Typography.labelLarge)
                            .foregroundStyle(.white)
                            .padding(.horizontal, Spacing.lg)
                            .padding(.vertical, Spacing.sm)
                            .background(Color.Accent.primary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .pressEffect()
                }
            }
        }
        .padding(Spacing.lg)
    }

    // MARK: - Empty State View

    var emptyStateView: some View {
        ContentUnavailableView(
            Constants.emptyTitle,
            systemImage: "newspaper",
            description: Text(Constants.emptyMessage)
        )
    }

    // MARK: - Breaking News Carousel

    @ViewBuilder
    var breakingNewsCarousel: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: Spacing.md) {
                ForEach(viewModel.viewState.breakingNews) { item in
                    GeometryReader { proxy in
                        HeroNewsCard(item: item, cardWidth: proxy.size.width) {
                            viewModel.handle(event: .onArticleTapped(articleId: item.id))
                        }
                    }
                    .aspectRatio(300.0 / 200.0, contentMode: .fit)
                    .fadeIn(delay: Double(item.animationIndex) * 0.1)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
        } else {
            ScrollView(.horizontal) {
                LazyHStack(spacing: Spacing.md) {
                    ForEach(viewModel.viewState.breakingNews) { item in
                        HeroNewsCard(item: item, cardWidth: heroCardWidth) {
                            viewModel.handle(event: .onArticleTapped(articleId: item.id))
                        }
                        .fadeIn(delay: Double(item.animationIndex) * 0.1)
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
            }
            .scrollIndicators(.hidden)
        }
    }

    // MARK: - Recently Read Carousel

    @ViewBuilder
    var recentlyReadCarousel: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: Spacing.md) {
                ForEach(viewModel.viewState.recentlyRead) { item in
                    GlassArticleCardCompact(
                        title: item.title,
                        sourceName: item.sourceName,
                        imageURL: item.imageURL,
                        onTap: {
                            viewModel.handle(event: .onRecentlyReadTapped(articleId: item.id))
                        }
                    )
                    .fadeIn(delay: Double(item.animationIndex) * 0.05)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
        } else {
            ScrollView(.horizontal) {
                LazyHStack(spacing: Spacing.sm) {
                    ForEach(viewModel.viewState.recentlyRead) { item in
                        GlassArticleCardCompact(
                            title: item.title,
                            sourceName: item.sourceName,
                            imageURL: item.imageURL,
                            onTap: {
                                viewModel.handle(event: .onRecentlyReadTapped(articleId: item.id))
                            }
                        )
                        .frame(width: recentlyReadCardWidth)
                        .fadeIn(delay: Double(item.animationIndex) * 0.05)
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
            }
            .scrollIndicators(.hidden)
        }
    }

    // MARK: - Image Prefetching

    /// Prefetches images for upcoming articles to reduce visible loading delays during scrolling.
    func prefetchUpcomingImages(from currentIndex: Int, in articles: [ArticleViewItem]) {
        let prefetchCount = 5
        let endIndex = min(currentIndex + prefetchCount, articles.count)
        guard endIndex > currentIndex else { return }

        let upcomingURLs = articles[currentIndex ..< endIndex]
            .compactMap { $0.imageURL }

        guard !upcomingURLs.isEmpty else { return }
        Task {
            await ImagePrefetcher.shared.prefetch(urls: upcomingURLs)
        }
    }
}
