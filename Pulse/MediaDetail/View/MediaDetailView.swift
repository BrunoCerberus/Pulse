import Combine
import EntropyCore
import SwiftUI

// MARK: - Constants

private enum Constants {
    static let back = String(localized: "common.back")
    static let share = String(localized: "common.share")
    static let openInBrowser = String(localized: "media.open_in_browser")
    static let errorTitle = String(localized: "media.error_title")
    static let videoUnavailable = String(localized: "media.video_unavailable")
    static let audioUnavailable = String(localized: "media.audio_unavailable")
}

// MARK: - MediaDetailView

/// Detail view for video and podcast media playback.
///
/// - Videos are displayed using an embedded WKWebView (YouTube, etc.)
/// - Podcasts are played using AVPlayer with custom controls
struct MediaDetailView: View {
    @StateObject private var viewModel: MediaDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private let serviceLocator: ServiceLocator

    init(article: Article, serviceLocator: ServiceLocator) {
        self.serviceLocator = serviceLocator
        _viewModel = StateObject(wrappedValue: MediaDetailViewModel(
            article: article,
            serviceLocator: serviceLocator
        ))
    }

    var body: some View {
        ZStack {
            // Background
            LinearGradient.subtleBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Player content
                    playerContent
                        .padding(.top, Spacing.md)

                    // Metadata section
                    metadataSection
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Label(Constants.back, systemImage: "chevron.left")
                        .labelStyle(.iconOnly)
                }
                .accessibilityIdentifier("backButton")
                .accessibilityLabel(Constants.back)
            }

            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: Spacing.sm) {
                    Button("", systemImage: viewModel.viewState.isBookmarked ? "bookmark.fill" : "bookmark") {
                        viewModel.handle(event: .onBookmarkTapped)
                    }
                    .accessibilityIdentifier(viewModel.viewState.isBookmarked ? "bookmark.fill" : "bookmark")
                    .accessibilityLabel(viewModel.viewState.isBookmarked ? "Remove bookmark" : "Add bookmark")

                    Button("", systemImage: "square.and.arrow.up") {
                        viewModel.handle(event: .onShareTapped)
                    }
                    .accessibilityIdentifier("shareButton")
                    .accessibilityLabel(Constants.share)
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { viewModel.viewState.showShareSheet },
            set: { if !$0 { viewModel.handle(event: .onShareDismissed) } }
        )) {
            if let url = URL(string: viewModel.viewState.article.url) {
                ShareSheet(activityItems: [url])
            }
        }
        .onAppear {
            viewModel.handle(event: .onAppear)
        }
        .enableSwipeBack()
    }

    private var videoPlayer: some View {
        VStack(spacing: Spacing.md) {
            if let mediaURL = viewModel.viewState.article.mediaURL {
                // YouTube videos: show thumbnail with play button (embedding often blocked)
                if mediaURL.contains("youtube.com") || mediaURL.contains("youtu.be") {
                    YouTubeThumbnailView(
                        urlString: mediaURL,
                        articleImageURL: viewModel.viewState.article.imageURL
                    )
                } else if let url = URL(string: mediaURL) {
                    // Direct video files: use VideoPlayerView
                    VideoPlayerView(
                        url: url,
                        onLoadingStarted: {
                            viewModel.handle(event: .onPlayerLoading)
                        },
                        onLoadingFinished: {
                            viewModel.handle(event: .onPlayerReady)
                        },
                        onError: { error in
                            viewModel.handle(event: .onError(error))
                        }
                    )
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                    .overlay {
                        if viewModel.viewState.isLoading {
                            RoundedRectangle(cornerRadius: CornerRadius.lg)
                                .fill(.black.opacity(0.5))
                                .overlay {
                                    ProgressView()
                                        .tint(.white)
                                }
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                } else {
                    errorView(message: Constants.videoUnavailable)
                }
            } else {
                errorView(message: Constants.videoUnavailable)
            }
        }
    }

    private var podcastPlayer: some View {
        AudioPlayerView(
            article: viewModel.viewState.article,
            onProgressUpdate: { progress, currentTime in
                viewModel.handle(event: .onProgressUpdate(progress: progress, currentTime: currentTime))
            },
            onDurationLoaded: { duration in
                viewModel.handle(event: .onDurationLoaded(duration))
            },
            onError: { error in
                viewModel.handle(event: .onError(error))
            },
            onLoadingChanged: { isLoading in
                if isLoading {
                    viewModel.handle(event: .onPlayerLoading)
                } else {
                    viewModel.handle(event: .onPlayerReady)
                }
            },
            onPlayStateChanged: { isPlaying in
                // Sync play state from player to view model
                if isPlaying != viewModel.viewState.isPlaying {
                    viewModel.handle(event: .onPlayPauseTapped)
                }
            }
        )
    }

    private var unsupportedMediaView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Unsupported media type")
                .font(Typography.bodyLarge)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
    }

    // MARK: - Metadata Section

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Title
            Text(viewModel.viewState.article.title)
                .font(Typography.titleLarge)
                .fontWeight(.bold)

            // Source and date
            HStack(spacing: Spacing.xs) {
                if let mediaType = viewModel.viewState.article.mediaType {
                    Image(systemName: mediaType.icon)
                        .foregroundStyle(mediaType.color)
                }

                Text(viewModel.viewState.article.source.name)
                    .fontWeight(.medium)

                Circle()
                    .fill(.secondary)
                    .frame(width: 3, height: 3)

                Text(viewModel.viewState.article.formattedDate)
            }
            .font(Typography.captionLarge)
            .foregroundStyle(.secondary)

            // Description
            if let description = viewModel.viewState.article.description {
                Rectangle()
                    .fill(Color.Border.adaptive(for: colorScheme))
                    .frame(height: 0.5)

                Text(description)
                    .font(Typography.bodyMedium)
                    .foregroundStyle(.primary.opacity(0.85))
                    .lineSpacing(4)
            }

            // Error message
            if let errorMessage = viewModel.viewState.errorMessage {
                errorBanner(message: errorMessage)
            }

            Rectangle()
                .fill(Color.Border.adaptive(for: colorScheme))
                .frame(height: 0.5)

            // Open in browser button
            openInBrowserButton
        }
        .padding(Spacing.lg)
        .background(.regularMaterial)
        .clipShape(
            .rect(
                topLeadingRadius: CornerRadius.xl,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: CornerRadius.xl
            )
        )
        .offset(y: -Spacing.lg)
    }

    // MARK: - Subviews

    private func errorView(message: String) -> some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.red.opacity(0.8))

            Text(Constants.errorTitle)
                .font(Typography.titleSmall)
                .fontWeight(.semibold)

            Text(message)
                .font(Typography.bodySmall)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
        .padding(.horizontal, Spacing.lg)
    }

    private func errorBanner(message: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)

            Text(message)
                .font(Typography.captionLarge)
                .foregroundStyle(.secondary)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
    }

    private var openInBrowserButton: some View {
        Button {
            HapticManager.shared.buttonPress()
            viewModel.handle(event: .onOpenInBrowserTapped)
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "safari.fill")
                Text(Constants.openInBrowser)
            }
            .font(Typography.labelLarge)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(Color.Accent.gradient)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
        }
        .pressEffect()
    }
}

// MARK: - Player Content

private extension MediaDetailView {
    @ViewBuilder
    var playerContent: some View {
        switch viewModel.viewState.article.mediaType {
        case .video:
            videoPlayer
        case .podcast:
            podcastPlayer
        case .none:
            unsupportedMediaView
        }
    }
}

#Preview("Video") {
    NavigationStack {
        MediaDetailView(
            article: Article(
                id: "1",
                title: "SwiftUI Best Practices for 2025",
                description: "Learn the latest SwiftUI techniques and patterns for building modern iOS apps.",
                source: ArticleSource(id: "youtube", name: "Swift Talk"),
                url: "https://www.youtube.com/watch?v=example",
                imageURL: "https://img.youtube.com/vi/example/maxresdefault.jpg",
                publishedAt: Date(),
                mediaType: .video,
                mediaURL: "https://www.youtube.com/watch?v=example",
                mediaDuration: 1800
            ),
            serviceLocator: .preview
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("Podcast") {
    NavigationStack {
        MediaDetailView(
            article: Article(
                id: "2",
                title: "The Future of AI in Software Development",
                description: "A deep dive into how AI is transforming the way we write code " +
                    "and what it means for developers.",
                source: ArticleSource(id: "podcast", name: "Tech Talk Daily"),
                url: "https://example.com/podcast",
                imageURL: nil,
                publishedAt: Date(),
                mediaType: .podcast,
                mediaURL: "https://example.com/audio.mp3",
                mediaDuration: 3600
            ),
            serviceLocator: .preview
        )
    }
    .preferredColorScheme(.dark)
}
