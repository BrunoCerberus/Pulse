import SwiftUI

// MARK: - Constants

private enum Constants {
    static let title = String(localized: "home.title")
    static let errorTitle = String(localized: "home.error.title")
    static let emptyTitle = String(localized: "home.empty.title")
    static let emptyMessage = String(localized: "home.empty.message")
    static let breaking = String(localized: "home.breaking")
    static let tryAgain = String(localized: "common.try_again")
    static let loadingMore = String(localized: "common.loading_more")
    static let allCategory = String(localized: "home.category.all", defaultValue: "All")
}

// MARK: - HomeView

/// Main home screen displaying breaking news and headline feeds.
///
/// This view follows the generic router pattern for testability, accepting any type
/// conforming to `HomeNavigationRouter` for navigation handling.
///
/// ## Features
/// - Breaking news carousel at the top
/// - Scrollable headline feed with infinite scroll
/// - Pull-to-refresh with cache invalidation
/// - Settings access via toolbar button
/// - Article sharing via share sheet
///
/// ## Usage
/// ```swift
/// HomeView(router: HomeNavigationRouter(coordinator: coordinator),
///          viewModel: HomeViewModel(serviceLocator: serviceLocator))
/// ```
struct HomeView<R: HomeNavigationRouter>: View {
    /// Router responsible for navigation actions
    private var router: R

    /// Backing ViewModel managing data and actions
    @ObservedObject var viewModel: HomeViewModel

    /// Creates the view with a router and ViewModel.
    /// - Parameters:
    ///   - router: Navigation router for routing actions
    ///   - viewModel: ViewModel for managing data and actions
    init(router: R, viewModel: HomeViewModel) {
        self.router = router
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                if viewModel.viewState.showCategoryTabs {
                    categoryTabBar
                }

                content
            }
        }
        .navigationTitle(Constants.title)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    HapticManager.shared.tap()
                    router.route(navigationEvent: .settings)
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: IconSize.md))
                        .foregroundStyle(.primary)
                }
                .accessibilityLabel("Settings")
                .accessibilityHint("Opens your preferences and account settings")
            }
        }
        .refreshable {
            HapticManager.shared.refresh()
            viewModel.handle(event: .onRefresh)
        }
        .sheet(item: Binding(
            get: { viewModel.viewState.articleToShare },
            set: { _ in viewModel.handle(event: .onShareDismissed) }
        )) { article in
            ShareSheet(activityItems: [URL(string: article.url) ?? article.title])
        }
        .onAppear {
            viewModel.handle(event: .onAppear)
        }
        .onChange(of: viewModel.viewState.selectedArticle) { _, newValue in
            if let article = newValue {
                router.route(navigationEvent: .articleDetail(article))
                viewModel.handle(event: .onArticleNavigated)
            }
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient.subtleBackground
    }

    // MARK: - Category Tab Bar

    private var categoryTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                // "All" tab - always first
                GlassTopicChip(
                    topic: Constants.allCategory,
                    isSelected: viewModel.viewState.selectedCategory == nil,
                    color: Color.Accent.primary
                ) {
                    viewModel.handle(event: .onCategorySelected(nil))
                }

                // Followed topics tabs
                ForEach(viewModel.viewState.followedTopics, id: \.self) { category in
                    GlassTopicChip(
                        topic: category.displayName,
                        isSelected: viewModel.viewState.selectedCategory == category,
                        color: category.color
                    ) {
                        viewModel.handle(event: .onCategorySelected(category))
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
        }
        .background(.ultraThinMaterial)
    }

    // MARK: - Content Views

    @ViewBuilder
    private var content: some View {
        let isInitialLoading = viewModel.viewState.isLoading && viewModel.viewState.headlines.isEmpty
        if viewModel.viewState.isRefreshing || isInitialLoading {
            loadingView
        } else if let error = viewModel.viewState.errorMessage {
            errorView(error)
        } else if viewModel.viewState.showEmptyState {
            emptyStateView
        } else {
            articlesList
        }
    }

    private var loadingView: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Only show breaking news skeleton when on "All" tab
                if viewModel.viewState.selectedCategory == nil {
                    GlassSectionHeader("Breaking News")

                    HeroCarouselSkeleton()
                }

                GlassSectionHeader("Top Headlines")

                ArticleListSkeleton(count: 5)
            }
        }
    }

    private func errorView(_ message: String) -> some View {
        GlassCard(style: .thin, shadowStyle: .medium, padding: Spacing.xl) {
            VStack(spacing: Spacing.md) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: IconSize.xxl))
                    .foregroundStyle(Color.Semantic.warning)

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
        .padding(Spacing.lg)
    }

    private var emptyStateView: some View {
        GlassCard(style: .thin, shadowStyle: .medium, padding: Spacing.xl) {
            VStack(spacing: Spacing.md) {
                Image(systemName: "newspaper")
                    .font(.system(size: IconSize.xxl))
                    .foregroundStyle(.secondary)

                Text(Constants.emptyTitle)
                    .font(Typography.titleMedium)

                Text(Constants.emptyMessage)
                    .font(Typography.bodyMedium)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(Spacing.lg)
    }

    private var articlesList: some View {
        let headlines = viewModel.viewState.headlines
        let lastItemId = headlines.last?.id
        let showBreakingNews = viewModel.viewState.selectedCategory == nil
            && !viewModel.viewState.breakingNews.isEmpty

        return ScrollView {
            LazyVStack(spacing: 0) {
                if showBreakingNews {
                    Section {
                        breakingNewsCarousel
                    } header: {
                        GlassSectionHeader("Breaking News")
                    }
                }

                Section {
                    LazyVStack(spacing: Spacing.sm) {
                        ForEach(headlines) { item in
                            GlassArticleCard(
                                item: item,
                                onTap: {
                                    viewModel.handle(event: .onArticleTapped(articleId: item.id))
                                },
                                onBookmark: {
                                    viewModel.handle(event: .onBookmarkTapped(articleId: item.id))
                                },
                                onShare: {
                                    viewModel.handle(event: .onShareTapped(articleId: item.id))
                                }
                            )
                            .fadeIn(delay: Double(item.animationIndex) * 0.03)
                            .onAppear {
                                // Pre-computed lastItemId avoids recalculating .last on every appear
                                if item.id == lastItemId {
                                    viewModel.handle(event: .onLoadMore)
                                }
                                // Prefetch next 5 images for smoother scrolling
                                // Index lookup only happens on appear, not every body render
                                if let index = headlines.firstIndex(where: { $0.id == item.id }) {
                                    prefetchUpcomingImages(from: index, in: headlines)
                                }
                            }
                            .onDisappear {
                                // Cancel prefetch for scrolled-past items to free resources
                                if let url = item.imageURL {
                                    Task {
                                        await ImagePrefetcher.shared.cancelPrefetch(for: [url])
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.sm)

                    if viewModel.viewState.isLoadingMore {
                        HStack {
                            ProgressView()
                                .tint(.secondary)
                            Text(Constants.loadingMore)
                                .font(Typography.captionLarge)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(Spacing.lg)
                    }
                } header: {
                    GlassSectionHeader("Top Headlines")
                }
            }
        }
    }

    /// Prefetches images for upcoming articles to reduce visible loading delays during scrolling.
    private func prefetchUpcomingImages(from currentIndex: Int, in articles: [ArticleViewItem]) {
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

    private var breakingNewsCarousel: some View {
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

#Preview {
    NavigationStack {
        HomeView(
            router: HomeNavigationRouter(),
            viewModel: HomeViewModel(serviceLocator: .preview)
        )
    }
}
