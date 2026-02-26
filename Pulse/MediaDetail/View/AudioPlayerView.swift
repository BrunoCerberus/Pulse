import EntropyCore
import SwiftUI

// MARK: - Constants

private enum Constants {
    static var skipBackward: String {
        AppLocalization.shared.localized("media.skip_backward")
    }

    static var skipForward: String {
        AppLocalization.shared.localized("media.skip_forward")
    }

    static var play: String {
        AppLocalization.shared.localized("media.play")
    }

    static var pause: String {
        AppLocalization.shared.localized("media.pause")
    }
}

/// Audio player UI for podcast playback.
///
/// Displays podcast artwork, metadata, progress slider, and playback controls.
/// Communicates with the parent view via callbacks for state updates.
struct AudioPlayerView: View {
    let article: Article
    @StateObject private var playerManager = AudioPlayerManager()

    @ScaledMetric(relativeTo: .largeTitle) private var headphonesIconSize: CGFloat = 64
    @ScaledMetric(relativeTo: .title) private var controlIconSize: CGFloat = 28
    @ScaledMetric(relativeTo: .title) private var playButtonSize: CGFloat = 72

    /// Callback when playback progress updates.
    var onProgressUpdate: ((Double, TimeInterval) -> Void)?

    /// Callback when duration is loaded.
    var onDurationLoaded: ((TimeInterval) -> Void)?

    /// Callback when an error occurs.
    var onError: ((String) -> Void)?

    /// Callback when loading state changes.
    var onLoadingChanged: ((Bool) -> Void)?

    /// Callback when play state changes.
    var onPlayStateChanged: ((Bool) -> Void)?

    @State private var isDragging = false
    @State private var dragProgress: Double = 0

    var body: some View {
        VStack(spacing: Spacing.xl) {
            // Artwork
            artworkImage
                .padding(.top, Spacing.lg)

            // Metadata
            metadataSection

            // Progress
            progressSection

            // Controls
            controlsSection
                .padding(.bottom, Spacing.lg)
        }
        .padding(.horizontal, Spacing.lg)
        .onAppear {
            loadAudio()
        }
        .onDisappear {
            playerManager.cleanup()
        }
        .onChange(of: playerManager.progress) { _, newProgress in
            if !isDragging {
                onProgressUpdate?(newProgress, playerManager.currentTime)
            }
        }
        .onChange(of: playerManager.duration) { _, newDuration in
            if newDuration > 0 {
                onDurationLoaded?(newDuration)
            }
        }
        .onChange(of: playerManager.error) { _, newError in
            if let error = newError {
                onError?(error)
            }
        }
        .onChange(of: playerManager.isLoading) { _, isLoading in
            onLoadingChanged?(isLoading)
        }
        .onChange(of: playerManager.isPlaying) { _, isPlaying in
            onPlayStateChanged?(isPlaying)
        }
    }

    // MARK: - Artwork

    private var artworkImage: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, 300)
            Group {
                if let imageURL = article.heroImageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            artworkPlaceholder
                                .overlay {
                                    ProgressView()
                                }
                        case let .success(image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            artworkPlaceholder
                        @unknown default:
                            artworkPlaceholder
                        }
                    }
                } else {
                    artworkPlaceholder
                }
            }
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
            .depthShadow(.floating)
            .frame(maxWidth: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: 300)
    }

    private var artworkPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [Color.Accent.secondary.opacity(0.6), Color.Accent.secondary.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: "headphones")
                .font(.system(size: headphonesIconSize))
                .foregroundStyle(.white.opacity(0.8))
        }
        .accessibilityHidden(true)
    }

    // MARK: - Metadata

    private var metadataSection: some View {
        VStack(spacing: Spacing.xs) {
            Text(article.title)
                .font(Typography.titleMedium)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text(article.source.name)
                .font(Typography.bodySmall)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, Spacing.md)
    }

    // MARK: - Progress

    private var progressSection: some View {
        VStack(spacing: Spacing.xs) {
            // Progress slider
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track background
                    Capsule()
                        .fill(Color.Glass.surface)
                        .frame(height: 4)

                    // Progress fill
                    Capsule()
                        .fill(Color.Accent.gradient)
                        .frame(width: geometry.size.width * displayProgress, height: 4)

                    // Thumb
                    Circle()
                        .fill(.white)
                        .frame(width: isDragging ? 16 : 12, height: isDragging ? 16 : 12)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                        .offset(x: (geometry.size.width * displayProgress) - (isDragging ? 8 : 6))
                        .animation(.easeOut(duration: 0.1), value: isDragging)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isDragging = true
                            let newProgress = min(max(value.location.x / geometry.size.width, 0), 1)
                            dragProgress = newProgress
                        }
                        .onEnded { value in
                            let finalProgress = min(max(value.location.x / geometry.size.width, 0), 1)
                            playerManager.seek(to: finalProgress)
                            isDragging = false
                        }
                )
            }
            .frame(height: 20)
            .accessibilityElement()
            .accessibilityLabel(AppLocalization.shared.localized("audio_player.progress_label"))
            .accessibilityValue({
                let time = isDragging ? playerManager.duration * dragProgress : playerManager.currentTime
                let current = formatTime(time)
                let total = formatTime(playerManager.duration)
                let format = AppLocalization.shared.localized("audio_player.progress_value")
                return String(format: format, current, total)
            }())
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment:
                    playerManager.skipForward(seconds: 30)
                case .decrement:
                    playerManager.skipBackward(seconds: 15)
                @unknown default:
                    break
                }
            }

            // Time labels
            HStack {
                Text(formatTime(isDragging ? playerManager.duration * dragProgress : playerManager.currentTime))
                    .font(Typography.captionMedium)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()

                Spacer()

                Text(formatTime(playerManager.duration))
                    .font(Typography.captionMedium)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, Spacing.md)
    }

    private var displayProgress: Double {
        isDragging ? dragProgress : playerManager.progress
    }

    // MARK: - Controls

    private var controlsSection: some View {
        HStack(spacing: Spacing.xxl) {
            // Skip backward 15s
            Button {
                HapticManager.shared.buttonPress()
                playerManager.skipBackward(seconds: 15)
            } label: {
                Image(systemName: "gobackward.15")
                    .font(.system(size: controlIconSize))
                    .foregroundStyle(.primary)
            }
            .accessibilityLabel(Constants.skipBackward)

            // Play/Pause
            Button {
                HapticManager.shared.buttonPress()
                if playerManager.isPlaying {
                    playerManager.pause()
                } else {
                    playerManager.play()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.Accent.gradient)
                        .frame(width: playButtonSize, height: playButtonSize)

                    if playerManager.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: controlIconSize))
                            .foregroundStyle(.white)
                            .offset(x: playerManager.isPlaying ? 0 : 2)
                    }
                }
            }
            .disabled(playerManager.isLoading)
            .accessibilityLabel(playerManager.isPlaying ? Constants.pause : Constants.play)

            // Skip forward 30s
            Button {
                HapticManager.shared.buttonPress()
                playerManager.skipForward(seconds: 30)
            } label: {
                Image(systemName: "goforward.30")
                    .font(.system(size: controlIconSize))
                    .foregroundStyle(.primary)
            }
            .accessibilityLabel(Constants.skipForward)
        }
    }

    // MARK: - Helpers

    private func loadAudio() {
        guard let mediaURLString = article.mediaURL,
              let url = URL(string: mediaURLString)
        else {
            onError?(AppLocalization.shared.localized("audio_player.no_url_error"))
            return
        }

        playerManager.load(url: url)
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }

        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
}

#Preview {
    AudioPlayerView(
        article: Article(
            id: "1",
            title: "The Future of AI in Software Development",
            description: "A deep dive into how AI is transforming the way we write code",
            source: ArticleSource(id: "podcast", name: "Tech Talk Daily"),
            url: "https://example.com/podcast",
            imageURL: nil,
            publishedAt: Date(),
            mediaType: .podcast,
            mediaURL: "https://example.com/audio.mp3",
            mediaDuration: 3600
        )
    )
    .background(Color(.systemBackground))
    .preferredColorScheme(.dark)
}
