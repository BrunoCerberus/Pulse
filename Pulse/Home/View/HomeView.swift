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
}

// MARK: - HomeView

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

            content
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
                GlassSectionHeader("Breaking News")

                HeroCarouselSkeleton()

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
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                if !viewModel.viewState.breakingNews.isEmpty {
                    Section {
                        breakingNewsCarousel
                    } header: {
                        GlassSectionHeader("Breaking News")
                    }
                }

                Section {
                    LazyVStack(spacing: Spacing.sm) {
                        ForEach(Array(viewModel.viewState.headlines.enumerated()), id: \.element.id) { index, item in
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
                            .fadeIn(delay: Double(index) * 0.03)
                            .onAppear {
                                if item.id == viewModel.viewState.headlines.last?.id {
                                    viewModel.handle(event: .onLoadMore)
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

    private var breakingNewsCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: Spacing.md) {
                ForEach(Array(viewModel.viewState.breakingNews.enumerated()), id: \.element.id) { index, item in
                    HeroNewsCard(item: item) {
                        viewModel.handle(event: .onArticleTapped(articleId: item.id))
                    }
                    .fadeIn(delay: Double(index) * 0.1)
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
