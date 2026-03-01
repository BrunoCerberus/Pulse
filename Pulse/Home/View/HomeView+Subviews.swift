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
                    GlassSectionHeader(HomeViewConstants.breakingNews)
                    HeroCarouselSkeleton()
                }

                GlassSectionHeader(HomeViewConstants.topHeadlines)
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

                    Text(HomeViewConstants.offlineTitle)
                        .font(Typography.titleMedium)

                    Text(HomeViewConstants.offlineMessage)
                        .font(Typography.bodyMedium)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: IconSize.xxl))
                        .foregroundStyle(Color.Semantic.warning)
                        .accessibilityHidden(true)

                    Text(HomeViewConstants.errorTitle)
                        .font(Typography.titleMedium)

                    Text(message)
                        .font(Typography.bodyMedium)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button {
                        HapticManager.shared.tap()
                        viewModel.handle(event: .onRefresh)
                    } label: {
                        Text(HomeViewConstants.tryAgain)
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
        GlassCard(style: .thin, shadowStyle: .medium, padding: Spacing.xl) {
            VStack(spacing: Spacing.md) {
                Image(systemName: "newspaper")
                    .font(.system(size: IconSize.xxl))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)

                Text(HomeViewConstants.emptyTitle)
                    .font(Typography.titleMedium)

                Text(HomeViewConstants.emptyMessage)
                    .font(Typography.bodyMedium)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(Spacing.lg)
    }

    // MARK: - Breaking News Carousel

    @ViewBuilder
    var breakingNewsCarousel: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: Spacing.md) {
                ForEach(viewModel.viewState.breakingNews) { item in
                    HeroNewsCard(item: item) {
                        viewModel.handle(event: .onArticleTapped(articleId: item.id))
                    }
                    .fadeIn(delay: Double(item.animationIndex) * 0.1)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: Spacing.md) {
                    ForEach(viewModel.viewState.breakingNews) { item in
                        HeroNewsCard(item: item) {
                            viewModel.handle(event: .onArticleTapped(articleId: item.id))
                        }
                        .fadeIn(delay: Double(item.animationIndex) * 0.1)
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
            }
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
