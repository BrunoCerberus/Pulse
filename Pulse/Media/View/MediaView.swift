import EntropyCore
import SwiftUI

// MARK: - Constants

private enum Constants {
    static var title: String {
        AppLocalization.shared.localized("media.title")
    }

    static var featured: String {
        AppLocalization.shared.localized("media.featured")
    }

    static var latest: String {
        AppLocalization.shared.localized("media.latest")
    }

    static var all: String {
        AppLocalization.shared.localized("media.all_types")
    }

    static var errorTitle: String {
        AppLocalization.shared.localized("media.error.title")
    }

    static var emptyTitle: String {
        AppLocalization.shared.localized("media.empty.title")
    }

    static var emptyMessage: String {
        AppLocalization.shared.localized("media.empty.message")
    }

    static var offlineTitle: String {
        AppLocalization.shared.localized("media.offline.title")
    }

    static var offlineMessage: String {
        AppLocalization.shared.localized("media.offline.message")
    }

    static var tryAgain: String {
        AppLocalization.shared.localized("common.try_again")
    }

    static var loadingMore: String {
        AppLocalization.shared.localized("common.loading_more")
    }
}

// MARK: - MediaView

/// Main media screen displaying videos and podcasts.
///
/// This view follows the generic router pattern for testability, accepting any type
/// conforming to `MediaNavigationRouter` for navigation handling.
///
/// ## Features
/// - Segmented control for filtering by media type (All/Videos/Podcasts)
/// - Featured media carousel at the top
/// - Scrollable media feed with infinite scroll
/// - Pull-to-refresh
/// - Staggered card animations
struct MediaView<R: MediaNavigationRouter>: View {
    /// Router responsible for navigation actions.
    private var router: R

    /// Backing ViewModel managing data and actions.
    @ObservedObject var viewModel: MediaViewModel

    /// Creates the view with a router and ViewModel.
    init(router: R, viewModel: MediaViewModel) {
        self.router = router
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            LinearGradient.subtleBackground
                .ignoresSafeArea()

            content
        }
        .navigationTitle(Constants.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .refreshable {
            HapticManager.shared.refresh()
            viewModel.handle(event: .onRefresh)
        }
        .sheet(item: Binding(
            get: { viewModel.viewState.mediaToShare },
            set: { _ in viewModel.handle(event: .onShareDismissed) }
        )) { article in
            ShareSheet(activityItems: [URL(string: article.url) ?? article.title])
        }
        .onAppear {
            viewModel.handle(event: .onAppear)
        }
        .onChange(of: viewModel.viewState.selectedMedia) { _, newValue in
            if let media = newValue {
                router.route(navigationEvent: .mediaDetail(media))
                viewModel.handle(event: .onMediaNavigated)
            }
        }
        .onChange(of: viewModel.viewState.mediaToPlay) { _, newValue in
            if let media = newValue {
                openMedia(media)
                viewModel.handle(event: .onPlayDismissed)
            }
        }
    }

    // MARK: - Content Views

    @ViewBuilder
    private var content: some View {
        let hasData = !viewModel.viewState.mediaItems.isEmpty || !viewModel.viewState.featuredMedia.isEmpty
        let isInitialLoading = viewModel.viewState.isLoading && !hasData
        if viewModel.viewState.isRefreshing || isInitialLoading {
            loadingView
        } else if hasData {
            // Show existing content even if a refresh failed (e.g., offline with cached data)
            mediaList
        } else if let error = viewModel.viewState.errorMessage {
            errorView(error)
        } else if viewModel.viewState.showEmptyState {
            emptyStateView
        } else {
            mediaList
        }
    }

    private var loadingView: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                mediaTypeSelector

                GlassSectionHeader(Constants.featured)
                FeaturedMediaCarouselSkeleton()

                GlassSectionHeader(Constants.latest)
                MediaListSkeleton(count: 5)
            }
        }
        .accessibilityHidden(true)
    }

    private func errorView(_ message: String) -> some View {
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

    private var emptyStateView: some View {
        GlassCard(style: .thin, shadowStyle: .medium, padding: Spacing.xl) {
            VStack(spacing: Spacing.md) {
                Image(systemName: "play.rectangle.on.rectangle")
                    .font(.system(size: IconSize.xxl))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)

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

    private var mediaList: some View {
        let mediaItems = viewModel.viewState.mediaItems
        let lastItemId = mediaItems.last?.id
        let showFeatured = !viewModel.viewState.featuredMedia.isEmpty

        return ScrollView {
            LazyVStack(spacing: 0) {
                mediaTypeSelector

                if showFeatured {
                    Section {
                        featuredCarousel
                    } header: {
                        GlassSectionHeader(Constants.featured)
                    }
                }

                Section {
                    LazyVStack(spacing: Spacing.sm) {
                        ForEach(mediaItems) { item in
                            MediaCard(
                                item: item,
                                onTap: {
                                    viewModel.handle(event: .onMediaTapped(mediaId: item.id))
                                },
                                onPlay: {
                                    viewModel.handle(event: .onPlayTapped(mediaId: item.id))
                                },
                                onShare: {
                                    viewModel.handle(event: .onShareTapped(mediaId: item.id))
                                }
                            )
                            .fadeIn(delay: Double(item.animationIndex) * 0.03)
                            .onAppear {
                                if item.id == lastItemId {
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
                    GlassSectionHeader(Constants.latest)
                }
            }
        }
    }

    // MARK: - Media Type Selector

    private var mediaTypeSelector: some View {
        MediaSegmentedControl(
            selectedType: viewModel.viewState.selectedType,
            onSelect: { type in
                HapticManager.shared.selectionChanged()
                viewModel.handle(event: .onMediaTypeSelected(type))
            }
        )
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }

    // MARK: - Featured Carousel

    private var featuredCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: Spacing.md) {
                ForEach(viewModel.viewState.featuredMedia) { item in
                    FeaturedMediaCard(item: item) {
                        viewModel.handle(event: .onMediaTapped(mediaId: item.id))
                    }
                    .fadeIn(delay: Double(item.animationIndex) * 0.1)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
        }
    }

    // MARK: - Media Playback

    private func openMedia(_ media: Article) {
        let urlString = media.mediaURL ?? media.url
        guard let url = URL(string: urlString),
              let scheme = url.scheme?.lowercased(),
              ["https", "http"].contains(scheme)
        else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MediaView(
            router: MediaNavigationRouter(),
            viewModel: MediaViewModel(serviceLocator: .preview)
        )
    }
    .preferredColorScheme(.dark)
}
