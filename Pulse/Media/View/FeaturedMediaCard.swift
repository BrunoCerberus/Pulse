import EntropyCore
import SwiftUI

/// Large hero card for displaying featured media in the carousel.
///
/// Features:
/// - Large hero image (280x180)
/// - Central play button
/// - Gradient overlay with content
/// - Media type badge with color
/// - Duration display
struct FeaturedMediaCard: View {
    let item: MediaViewItem
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private let cardWidth: CGFloat = 280
    private let cardHeight: CGFloat = 180

    private var effectiveCardWidth: CGFloat {
        let screenWidth = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.screen.bounds.width ?? cardWidth
        return dynamicTypeSize.isAccessibilitySize ? screenWidth - Spacing.lg * 2 : cardWidth
    }

    private var effectiveCardHeight: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 220 : cardHeight
    }

    private var mediaAccessibilityLabel: String {
        var parts = [String]()
        if let mediaType = item.mediaType {
            parts.append(mediaType.displayName)
        }
        parts.append(item.title)
        parts.append(String(format: AppLocalization.localized("accessibility.from_source"), item.sourceName))
        if let duration = item.formattedDuration {
            parts.append(duration)
        }
        return parts.joined(separator: ". ")
    }

    var body: some View {
        Button {
            HapticManager.shared.tap()
            onTap()
        } label: {
            ZStack {
                imageBackground

                LinearGradient.heroOverlay

                playButton

                contentOverlay
            }
            .frame(width: effectiveCardWidth, height: effectiveCardHeight)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                    .stroke(Color.Border.glass, lineWidth: 0.5)
            )
            .depthShadow(.elevated)
        }
        .pressEffect()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(mediaAccessibilityLabel)
        .accessibilityHint(AppLocalization.localized("media.play_hint"))
    }

    // MARK: - Image Background

    @ViewBuilder
    private var imageBackground: some View {
        if let imageURL = item.heroImageURL ?? item.imageURL {
            CachedAsyncImage(url: imageURL, accessibilityLabel: item.title) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: effectiveCardWidth, height: effectiveCardHeight)
                    .clipped()
            } placeholder: {
                placeholderBackground
                    .overlay {
                        ProgressView()
                            .tint(.white)
                    }
            }
        } else {
            placeholderBackground
                .overlay {
                    Image(systemName: item.mediaType?.icon ?? "play.rectangle")
                        .font(.system(size: IconSize.xxl))
                        .foregroundStyle(.white.opacity(0.5))
                }
        }
    }

    private var placeholderBackground: some View {
        LinearGradient(
            colors: [
                item.mediaType?.color.opacity(0.6) ?? Color.purple.opacity(0.6),
                Color.blue.opacity(0.4),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Play Button

    private var playButton: some View {
        Circle()
            .fill(.white.opacity(0.9))
            .frame(width: 48, height: 48)
            .overlay {
                Image(systemName: "play.fill")
                    .font(.system(size: IconSize.lg))
                    .foregroundStyle(.black)
                    .offset(x: 2) // Optical centering for play icon
            }
            .depthShadow(.elevated)
            .accessibilityHidden(true)
    }

    // MARK: - Content Overlay

    private var contentOverlay: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Spacer()

            if let mediaType = item.mediaType {
                mediaTypeBadge(mediaType)
            }

            Text(item.title)
                .font(Typography.headlineLarge)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 4 : 2)
                .multilineTextAlignment(.leading)

            metadataRow
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [.clear, .black.opacity(0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .background(.ultraThinMaterial.opacity(0.3))
    }

    private func mediaTypeBadge(_ type: MediaType) -> some View {
        HStack(spacing: Spacing.xxs) {
            Image(systemName: type.icon)
            Text(type.displayName.uppercased())
        }
        .font(Typography.labelSmall)
        .fontWeight(.bold)
        .foregroundStyle(.white)
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, Spacing.xxs)
        .background(Capsule().fill(type.color))
    }

    private var metadataRow: some View {
        HStack(spacing: Spacing.xs) {
            Text(item.sourceName)
                .font(Typography.captionMedium)
                .fontWeight(.medium)

            if let duration = item.formattedDuration {
                Circle()
                    .fill(.white.opacity(0.6))
                    .frame(width: 3, height: 3)
                    .accessibilityHidden(true)

                Text(duration)
                    .font(Typography.captionMedium)
            }
        }
        .foregroundStyle(.white.opacity(0.9))
    }
}

// MARK: - Preview

#Preview("Featured Media Card") {
    ZStack {
        LinearGradient.meshFallback
            .ignoresSafeArea()

        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.md) {
                FeaturedMediaCard(
                    item: MediaViewItem(
                        from: Article(
                            id: "1",
                            title: "iPhone 16 Pro Max Review",
                            source: ArticleSource(id: "mkbhd", name: "MKBHD"),
                            url: "https://youtube.com",
                            imageURL: "https://picsum.photos/400/300",
                            publishedAt: Date(),
                            mediaType: .video,
                            mediaDuration: 1245
                        )
                    ),
                    onTap: {}
                )

                FeaturedMediaCard(
                    item: MediaViewItem(
                        from: Article(
                            id: "2",
                            title: "The Science of Sleep Explained",
                            source: ArticleSource(id: "huberman", name: "Huberman Lab"),
                            url: "https://podcasts.apple.com",
                            imageURL: "https://picsum.photos/401/301",
                            publishedAt: Date().addingTimeInterval(-3600),
                            mediaType: .podcast,
                            mediaDuration: 7200
                        )
                    ),
                    onTap: {}
                )

                FeaturedMediaCard(
                    item: MediaViewItem(
                        from: Article(
                            id: "3",
                            title: "No Image Card Test",
                            source: ArticleSource(id: "test", name: "Test"),
                            url: "https://example.com",
                            publishedAt: Date(),
                            mediaType: .video,
                            mediaDuration: 100
                        )
                    ),
                    onTap: {}
                )
            }
            .padding()
        }
    }
    .preferredColorScheme(.dark)
}
