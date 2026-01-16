import Combine
import EntropyCore
import SwiftUI

// MARK: - Constants

private enum Constants {
    static let title = String(localized: "for_you.title")
    static let errorTitle = String(localized: "for_you.error.title")
    static let emptyTitle = String(localized: "for_you.empty.title")
    static let emptyMessage = String(localized: "for_you.empty.message")
    static let setPreferences = String(localized: "for_you.set_preferences")
    static let noArticlesTitle = String(localized: "for_you.no_articles.title")
    static let noArticlesMessage = String(localized: "for_you.no_articles.message")
    static let tryAgain = String(localized: "common.try_again")
    static let loadingMore = String(localized: "common.loading_more")
}

// MARK: - ForYouView

struct ForYouView<R: ForYouNavigationRouter>: View {
    /// Router responsible for navigation actions
    private var router: R

    /// Service locator for dependency injection
    private let serviceLocator: ServiceLocator

    /// Backing ViewModel managing data and actions
    @ObservedObject var viewModel: ForYouViewModel

    /// Premium status tracking
    @State private var isPremium = false
    @State private var subscriptionCancellable: AnyCancellable?

    /// Creates the view with a router and ViewModel.
    /// - Parameters:
    ///   - router: Navigation router for routing actions
    ///   - viewModel: ViewModel for managing data and actions
    ///   - serviceLocator: Service locator for dependency injection
    init(router: R, viewModel: ForYouViewModel, serviceLocator: ServiceLocator) {
        self.router = router
        self.viewModel = viewModel
        self.serviceLocator = serviceLocator
    }

    var body: some View {
        Group {
            if isPremium {
                premiumContent
            } else {
                PremiumGateView(
                    feature: .forYouFeed,
                    serviceLocator: serviceLocator
                )
                .navigationTitle(Constants.title)
            }
        }
        .onAppear {
            checkPremiumStatus()
            observeSubscriptionStatus()
        }
        .onDisappear {
            subscriptionCancellable?.cancel()
        }
    }

    private var premiumContent: some View {
        ZStack {
            LinearGradient.subtleBackground
                .ignoresSafeArea()

            content
        }
        .navigationTitle(Constants.title)
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

    private func checkPremiumStatus() {
        do {
            let storeKitService = try serviceLocator.retrieve(StoreKitService.self)
            isPremium = storeKitService.isPremium
        } catch {
            isPremium = false
        }
    }

    private func observeSubscriptionStatus() {
        do {
            let storeKitService = try serviceLocator.retrieve(StoreKitService.self)
            subscriptionCancellable = storeKitService.subscriptionStatusPublisher
                .receive(on: DispatchQueue.main)
                .sink { [self] newStatus in
                    self.isPremium = newStatus
                }
        } catch {
            // Service not available
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

                Text(Constants.emptyTitle)
                    .font(Typography.displaySmall)

                Text(Constants.emptyMessage)
                    .font(Typography.bodyMedium)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    HapticManager.shared.buttonPress()
                    router.route(navigationEvent: .settings)
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "gearshape.fill")
                        Text(Constants.setPreferences)
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

                Text(Constants.noArticlesTitle)
                    .font(Typography.titleMedium)

                Text(Constants.noArticlesMessage)
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
                            ForEach(Array(viewModel.viewState.articles.enumerated()), id: \.element.id) { index, item in
                                GlassArticleCard(
                                    item: item,
                                    onTap: {
                                        viewModel.handle(event: .onArticleTapped(articleId: item.id))
                                    },
                                    onBookmark: {},
                                    onShare: {}
                                )
                                .fadeIn(delay: Double(index) * 0.03)
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
                                Text(Constants.loadingMore)
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
            viewModel: ForYouViewModel(serviceLocator: .preview),
            serviceLocator: .preview
        )
    }
}
