import SwiftUI

struct ForYouView<R: ForYouNavigationRouter>: View {
    /// Router responsible for navigation actions
    private var router: R

    /// Backing ViewModel managing data and actions
    @ObservedObject var viewModel: ForYouViewModel

    /// Creates the view with a router and ViewModel.
    /// - Parameters:
    ///   - router: Navigation router for routing actions
    ///   - viewModel: ViewModel for managing data and actions
    init(router: R, viewModel: ForYouViewModel) {
        self.router = router
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            LinearGradient.subtleBackground
                .ignoresSafeArea()

            content
        }
        .navigationTitle(String(localized: "for_you.title"))
        .toolbarBackground(.hidden, for: .navigationBar)
        .refreshable {
            HapticManager.shared.refresh()
            viewModel.handle(event: .onRefresh)
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

    @ViewBuilder
    private var content: some View {
        if viewModel.viewState.isRefreshing || (viewModel.viewState.isLoading && viewModel.viewState.articles.isEmpty) {
            loadingView
        } else if let error = viewModel.viewState.errorMessage {
            errorView(error)
        } else if viewModel.viewState.showOnboarding {
            onboardingView
        } else if viewModel.viewState.showEmptyState {
            emptyStateView
        } else {
            articlesList
        }
    }

    private var loadingView: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                GlassSectionHeader("For You")

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

                Text(String(localized: "for_you.error.title"))
                    .font(Typography.titleMedium)

                Text(message)
                    .font(Typography.bodyMedium)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    HapticManager.shared.tap()
                    viewModel.handle(event: .onRefresh)
                } label: {
                    Text(String(localized: "common.try_again"))
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

    private var onboardingView: some View {
        GlassCard(style: .regular, shadowStyle: .elevated, padding: Spacing.xl) {
            VStack(spacing: Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(Color.Accent.gradient)
                        .frame(width: 100, height: 100)

                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: IconSize.xxl))
                        .foregroundStyle(.white)
                }
                .glowEffect(color: Color.Accent.primary, radius: 16)

                Text(String(localized: "for_you.empty.title"))
                    .font(Typography.displaySmall)

                Text(String(localized: "for_you.empty.message"))
                    .font(Typography.bodyMedium)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    HapticManager.shared.buttonPress()
                    router.route(navigationEvent: .settings)
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "gearshape.fill")
                        Text(String(localized: "for_you.set_preferences"))
                    }
                    .font(Typography.labelLarge)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(Color.Accent.gradient)
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

                Text(String(localized: "for_you.no_articles.title"))
                    .font(Typography.titleMedium)

                Text(String(localized: "for_you.no_articles.message"))
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
                if !viewModel.viewState.followedTopics.isEmpty {
                    Section {
                        LazyVStack(spacing: Spacing.sm) {
                            ForEach(viewModel.viewState.articles) { item in
                                GlassArticleCard(
                                    item: item,
                                    onTap: {
                                        viewModel.handle(event: .onArticleTapped(articleId: item.id))
                                    },
                                    onBookmark: {},
                                    onShare: {}
                                )
                                .onAppear {
                                    if item.id == viewModel.viewState.articles.last?.id {
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
                                Text(String(localized: "common.loading_more"))
                                    .font(Typography.captionLarge)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(Spacing.lg)
                        }
                    } header: {
                        followedTopicsBar
                    }
                }
            }
        }
    }

    private var followedTopicsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(viewModel.viewState.followedTopics) { topic in
                    GlassTopicChip(
                        topic: topic.displayName,
                        isSelected: true,
                        color: topic.color
                    ) {}
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
        }
        .background(.ultraThinMaterial)
    }
}

#Preview {
    NavigationStack {
        ForYouView(
            router: ForYouNavigationRouter(),
            viewModel: ForYouViewModel(serviceLocator: .preview)
        )
    }
}
