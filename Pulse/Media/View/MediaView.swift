import EntropyCore
import SwiftUI

// MARK: - Constants

private enum Constants {
    static let title = String(localized: "media.title", defaultValue: "Media")
    static let featured = String(localized: "media.featured", defaultValue: "Featured")
    static let latest = String(localized: "media.latest", defaultValue: "Latest")
    static let all = String(localized: "media.all_types", defaultValue: "All")
    static let errorTitle = String(localized: "media.error.title", defaultValue: "Unable to Load Media")
    static let emptyTitle = String(localized: "media.empty.title", defaultValue: "No Media")
    static let emptyMessage = String(
        localized: "media.empty.message",
        defaultValue: "Check back later for new videos and podcasts."
    )
    static let tryAgain = String(localized: "common.try_again", defaultValue: "Try Again")
    static let loadingMore = String(localized: "common.loading_more", defaultValue: "Loading more...")
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
        let isInitialLoading = viewModel.viewState.isLoading && viewModel.viewState.mediaItems.isEmpty
        if viewModel.viewState.isRefreshing || isInitialLoading {
            loadingView
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
                Image(systemName: "play.rectangle.on.rectangle")
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
        // Open in Safari/YouTube/Podcast app
        let urlString = media.mediaURL ?? media.url
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Skeleton Views

private struct FeaturedMediaCarouselSkeleton: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.md) {
                ForEach(0 ..< 3, id: \.self) { index in
                    FeaturedMediaCardSkeleton()
                        .fadeIn(delay: Double(index) * 0.1)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
        }
    }
}

private struct FeaturedMediaCardSkeleton: View {
    @State private var isAnimating = false

    private let cardWidth: CGFloat = 280
    private let cardHeight: CGFloat = 180

    var body: some View {
        ZStack {
            Color.primary.opacity(0.08)

            LinearGradient.heroOverlay

            // Intentionally omit play button in skeleton state

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Spacer()

                SkeletonShape(width: 90, height: 22, cornerRadius: CornerRadius.pill)

                SkeletonShape(height: 18)
                SkeletonShape(width: 220, height: 18)

                HStack(spacing: Spacing.xs) {
                    SkeletonShape(width: 80, height: 12)
                    SkeletonShape(width: 60, height: 12)
                }
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial.opacity(0.3))
        }
        .frame(width: cardWidth, height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                .stroke(Color.Border.glass, lineWidth: 0.5)
        )
        .shimmer(isActive: isAnimating)
        .onAppear {
            isAnimating = true
        }
    }
}

private struct MediaListSkeleton: View {
    let count: Int

    var body: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(0 ..< count, id: \.self) { _ in
                HStack(alignment: .top, spacing: Spacing.sm) {
                    RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous)
                        .fill(Color.primary.opacity(0.05))
                        .frame(width: 120, height: 80)
                        .shimmer()

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        RoundedRectangle(cornerRadius: CornerRadius.xs)
                            .fill(Color.primary.opacity(0.05))
                            .frame(height: 16)
                            .shimmer()

                        RoundedRectangle(cornerRadius: CornerRadius.xs)
                            .fill(Color.primary.opacity(0.05))
                            .frame(width: 150, height: 16)
                            .shimmer()

                        Spacer()

                        RoundedRectangle(cornerRadius: CornerRadius.xs)
                            .fill(Color.primary.opacity(0.05))
                            .frame(width: 100, height: 12)
                            .shimmer()
                    }
                    .frame(height: 80)

                    Spacer()
                }
                .padding(Spacing.md)
                .glassBackground(style: .solid, cornerRadius: CornerRadius.lg)
            }
        }
        .padding(.horizontal, Spacing.md)
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
}
