import EntropyCore
import SwiftUI

/// A view that shows a YouTube video thumbnail with a play button overlay.
/// Tapping opens the video in YouTube app or Safari.
struct YouTubeThumbnailView: View {
    let urlString: String
    let articleImageURL: String?

    @ScaledMetric(relativeTo: .title) private var playButtonSize: CGFloat = 68
    @ScaledMetric(relativeTo: .title) private var playIconSize: CGFloat = 28
    @ScaledMetric(relativeTo: .largeTitle) private var placeholderIconSize: CGFloat = 48

    var body: some View {
        let thumbnailURL = extractYouTubeThumbnail(from: urlString)

        Button {
            HapticManager.shared.buttonPress()
            if let url = URL(string: urlString) {
                UIApplication.shared.open(url)
            }
        } label: {
            ZStack {
                // Thumbnail or fallback from article
                if let thumbnailURL, let url = URL(string: thumbnailURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            thumbnailPlaceholder
                        case let .success(image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            // Try article's imageURL as fallback
                            articleImageFallback
                        @unknown default:
                            thumbnailPlaceholder
                        }
                    }
                } else {
                    articleImageFallback
                }

                // Dark overlay for better contrast
                Rectangle()
                    .fill(Color.Glass.overlay)

                // Play button
                VStack(spacing: Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(.red)
                            .frame(width: playButtonSize, height: playButtonSize)

                        Image(systemName: "play.fill")
                            .font(.system(size: playIconSize))
                            .foregroundStyle(.white)
                            .offset(x: 2)
                    }
                    .shadow(color: .black.opacity(0.4), radius: 8)

                    Text("Watch on YouTube")
                        .font(Typography.labelMedium)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.xs)
                        .background(Color.Glass.overlay.opacity(2.33))
                        .clipShape(Capsule())
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Watch video on YouTube")
        .aspectRatio(16 / 9, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .padding(.horizontal, Spacing.md)
    }

    private var thumbnailPlaceholder: some View {
        Rectangle()
            .fill(Color.Glass.surface)
            .overlay {
                ProgressView()
                    .tint(.white)
            }
    }

    @ViewBuilder
    private var articleImageFallback: some View {
        if let imageURL = articleImageURL,
           let url = URL(string: imageURL)
        {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    thumbnailPlaceholder
                case let .success(image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    videoPlaceholder
                @unknown default:
                    videoPlaceholder
                }
            }
        } else {
            videoPlaceholder
        }
    }

    private var videoPlaceholder: some View {
        Rectangle()
            .fill(Color.Glass.surface)
            .overlay {
                Image(systemName: "play.rectangle.fill")
                    .font(.system(size: placeholderIconSize))
                    .foregroundStyle(.white.opacity(0.6))
            }
    }

    private func extractYouTubeThumbnail(from urlString: String) -> String? {
        var videoID: String?

        if urlString.contains("youtube.com/watch") {
            if let components = URLComponents(string: urlString) {
                videoID = components.queryItems?.first(where: { $0.name == "v" })?.value
            }
        } else if urlString.contains("youtu.be/") {
            let parts = urlString.components(separatedBy: "youtu.be/")
            if parts.count > 1 {
                videoID = parts[1].components(separatedBy: "?").first
            }
        }

        guard let id = videoID else { return nil }
        return "https://img.youtube.com/vi/\(id)/maxresdefault.jpg"
    }
}

#Preview {
    YouTubeThumbnailView(
        urlString: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
        articleImageURL: nil
    )
    .preferredColorScheme(.dark)
}
