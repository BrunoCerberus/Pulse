import EntropyCore
import SwiftUI

// MARK: - Constants

enum HomeViewConstants {
    static let title = String(localized: "home.title")
    static let errorTitle = String(localized: "home.error.title")
    static let emptyTitle = String(localized: "home.empty.title")
    static let emptyMessage = String(localized: "home.empty.message")
    static let breaking = String(localized: "home.breaking")
    static let tryAgain = String(localized: "common.try_again")
    static let loadingMore = String(localized: "common.loading_more")
    static let allCategory = String(localized: "home.category.all")
    static let breakingNews = String(localized: "home.breaking_news")
    static let topHeadlines = String(localized: "home.top_headlines")
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
    // MARK: - Properties

    /// Router responsible for navigation actions
    private var router: R

    /// Backing ViewModel managing data and actions
    @ObservedObject var viewModel: HomeViewModel

    /// Namespace for matched geometry animation in category tabs
    @Namespace private var categoryAnimation

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
        .navigationTitle(HomeViewConstants.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: Spacing.sm) {
                    Button {
                        HapticManager.shared.tap()
                        viewModel.handle(event: .onEditTopicsTapped)
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.system(size: IconSize.md))
                            .foregroundStyle(.primary)
                    }
                    .accessibilityLabel(String(localized: "home.edit_topics.label"))
                    .accessibilityHint(String(localized: "home.edit_topics.hint"))

                    Button {
                        HapticManager.shared.tap()
                        router.route(navigationEvent: .settings)
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: IconSize.md))
                            .foregroundStyle(.primary)
                    }
                    .accessibilityLabel(String(localized: "home.settings.label"))
                    .accessibilityHint(String(localized: "home.settings.hint"))
                }
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
        .sheet(isPresented: Binding(
            get: { viewModel.viewState.isEditingTopics },
            set: { _ in viewModel.handle(event: .onEditTopicsDismissed) }
        )) {
            TopicEditorSheet(
                allTopics: viewModel.viewState.allTopics,
                followedTopics: viewModel.viewState.followedTopics,
                onToggleTopic: { topic in
                    viewModel.handle(event: .onToggleTopic(topic))
                },
                onDismiss: {
                    viewModel.handle(event: .onEditTopicsDismissed)
                }
            )
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

    var categoryTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                // "All" tab - always first
                categoryChip(
                    title: HomeViewConstants.allCategory,
                    color: Color.Accent.primary,
                    isSelected: viewModel.viewState.selectedCategory == nil
                ) {
                    viewModel.handle(event: .onCategorySelected(nil))
                }

                // Followed topics tabs
                ForEach(viewModel.viewState.followedTopics, id: \.self) { category in
                    categoryChip(
                        title: category.displayName,
                        color: category.color,
                        isSelected: viewModel.viewState.selectedCategory == category
                    ) {
                        viewModel.handle(event: .onCategorySelected(category))
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
        }
    }

    private func categoryChip(
        title: String,
        color: Color,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            HapticManager.shared.selectionChanged()
            withAnimation(AnimationTiming.springSmooth) {
                action()
            }
        } label: {
            Text(title)
                .font(Typography.labelMedium)
                .fontWeight(isSelected ? .semibold : .medium)
                .foregroundStyle(isSelected ? .white : color)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(color.gradient)
                            .matchedGeometryEffect(id: "categorySelection", in: categoryAnimation)
                    } else {
                        Capsule()
                            .fill(color.opacity(0.12))
                            .overlay(
                                Capsule()
                                    .stroke(color.opacity(0.25), lineWidth: 0.5)
                            )
                    }
                }
                .glowEffect(color: isSelected ? color : .clear, radius: 8)
        }
        .buttonStyle(.plain)
        .pressEffect(scale: 0.95)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(String(format: String(localized: "home.filter_category.hint"), title))
    }

    // MARK: - Content Views

    @ViewBuilder
    private var content: some View {
        let hasData = !viewModel.viewState.headlines.isEmpty || !viewModel.viewState.breakingNews.isEmpty
        let isInitialLoading = viewModel.viewState.isLoading && !hasData
        if viewModel.viewState.isRefreshing || isInitialLoading {
            loadingView
        } else if hasData {
            // Show existing content even if a refresh failed (e.g., offline with cached data)
            articlesList
        } else if let error = viewModel.viewState.errorMessage {
            errorView(error)
        } else if viewModel.viewState.showEmptyState {
            emptyStateView
        } else {
            articlesList
        }
    }

    // loadingView, errorView, emptyStateView moved to HomeView+Subviews.swift

    private var articlesList: some View {
        let headlines = viewModel.viewState.headlines
        let lastItemId = headlines.last?.id
        let showBreakingNews = viewModel.viewState.selectedCategory == nil
            && !viewModel.viewState.breakingNews.isEmpty

        return ScrollView {
            LazyVStack(spacing: 0) {
                // Category tabs at top of scrollable content
                if viewModel.viewState.showCategoryTabs {
                    categoryTabBar
                }

                if showBreakingNews {
                    Section {
                        breakingNewsCarousel
                    } header: {
                        GlassSectionHeader(HomeViewConstants.breakingNews)
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
                                if item.id == lastItemId {
                                    viewModel.handle(event: .onLoadMore)
                                }
                                prefetchUpcomingImages(from: item.animationIndex, in: headlines)
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
                            Text(HomeViewConstants.loadingMore)
                                .font(Typography.captionLarge)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(Spacing.lg)
                    }
                } header: {
                    GlassSectionHeader(HomeViewConstants.topHeadlines)
                }
            }
        }
    }

    // prefetchUpcomingImages, breakingNewsCarousel moved to HomeView+Subviews.swift
}

#Preview {
    NavigationStack {
        HomeView(
            router: HomeNavigationRouter(),
            viewModel: HomeViewModel(serviceLocator: .preview)
        )
    }
    .preferredColorScheme(.dark)
}
