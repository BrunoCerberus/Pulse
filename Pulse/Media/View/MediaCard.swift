import EntropyCore
import SwiftUI

/// Card component for displaying a media item (video or podcast) in a list.
///
/// Features:
/// - Thumbnail with play icon overlay
/// - Duration badge (bottom-right of thumbnail)
/// - Media type badge (Videos/Podcasts)
/// - Title, source, and date
/// - Context menu for play/share actions
struct MediaCard: View {
    let item: MediaViewItem
    let onTap: () -> Void
    let onPlay: () -> Void
    let onShare: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var mediaAccessibilityLabel: String {
        var parts = [String]()
        if let mediaType = item.mediaType {
            parts.append(mediaType.displayName)
        }
        parts.append(item.title)
        parts.append(String(format: AppLocalization.shared.localized("accessibility.from_source"), item.sourceName))
        parts.append(item.formattedDate)
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
            HStack(alignment: .top, spacing: Spacing.sm) {
                thumbnailView

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    if let mediaType = item.mediaType {
                        mediaTypeBadge(mediaType)
                    }

                    Text(item.title)
                        .font(Typography.headlineMedium)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.primary)

                    HStack(spacing: Spacing.xs) {
                        Text(item.sourceName)
                            .font(Typography.captionLarge)
                            .fontWeight(.medium)

                        Circle()
                            .fill(.secondary)
                            .frame(width: 3, height: 3)
                            .accessibilityHidden(true)

                        Text(item.formattedDate)
                            .font(Typography.captionLarge)
                    }
                    .foregroundStyle(.secondary)
                }

                Spacer(minLength: Spacing.xs)
            }
            .padding(Spacing.md)
            .glassBackground(style: .solid, cornerRadius: CornerRadius.lg)
            .depthShadow(.subtle)
        }
        .pressEffect()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(mediaAccessibilityLabel)
        .accessibilityHint(AppLocalization.shared.localized("media_card.details_hint"))
        .accessibilityIdentifier("mediaCard")
        .contextMenu {
            Button {
                onPlay()
            } label: {
                Label(AppLocalization.shared.localized("media.play"), systemImage: "play.fill")
            }

            Button {
                onShare()
            } label: {
                Label(AppLocalization.shared.localized("common.share"), systemImage: "square.and.arrow.up")
            }
        }
    }

    // MARK: - Thumbnail

    private var thumbnailView: some View {
        ZStack {
            if let imageURL = item.imageURL {
                CachedAsyncImage(url: imageURL, accessibilityLabel: item.title) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    thumbnailPlaceholder
                        .overlay {
                            ProgressView()
                                .tint(.secondary)
                        }
                }
            } else {
                thumbnailPlaceholder
            }

            // Play icon overlay
            playOverlay

            // Duration badge
            if let duration = item.formattedDuration {
                durationBadge(duration)
            }
        }
        .frame(width: 120, height: 80)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous)
                .stroke(Color.Border.adaptive(for: colorScheme), lineWidth: 0.5)
        )
    }

    private var thumbnailPlaceholder: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.05))
            .overlay {
                Image(systemName: item.mediaType?.icon ?? "play.rectangle")
                    .font(.system(size: IconSize.lg))
                    .foregroundStyle(.secondary.opacity(0.5))
            }
    }

    private var playOverlay: some View {
        Circle()
            .fill(Color.Glass.overlay.opacity(1.67))
            .frame(width: 44, height: 44)
            .overlay {
                Image(systemName: "play.fill")
                    .font(.system(size: IconSize.md))
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)
    }

    private func durationBadge(_ duration: String) -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Text(duration)
                    .font(Typography.captionSmall)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .padding(.horizontal, Spacing.xxs)
                    .padding(.vertical, 2)
                    .background(Color.Glass.overlay.opacity(2.5))
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xs))
                    .padding(Spacing.xxs)
            }
        }
    }

    private func mediaTypeBadge(_ type: MediaType) -> some View {
        HStack(spacing: Spacing.xxs) {
            Image(systemName: type.icon)
            Text(type.displayName)
        }
        .font(Typography.captionSmall)
        .fontWeight(.medium)
        .foregroundStyle(type.color)
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, 2)
        .background(type.color.opacity(0.15))
        .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview("Media Card") {
    ZStack {
        LinearGradient.meshFallback
            .ignoresSafeArea()

        ScrollView {
            VStack(spacing: Spacing.md) {
                MediaCard(
                    item: MediaViewItem(
                        from: Article(
                            id: "1",
                            title: "iPhone 16 Pro Max Review: The Best iPhone Yet?",
                            description: "A comprehensive look at Apple's latest flagship.",
                            source: ArticleSource(id: "mkbhd", name: "MKBHD"),
                            url: "https://youtube.com",
                            imageURL: "https://picsum.photos/200",
                            publishedAt: Date(),
                            mediaType: .video,
                            mediaURL: "https://youtube.com",
                            mediaDuration: 1245
                        )
                    ),
                    onTap: {},
                    onPlay: {},
                    onShare: {}
                )

                MediaCard(
                    item: MediaViewItem(
                        from: Article(
                            id: "2",
                            title: "The Daily: What's Next for AI Regulation",
                            description: "A look at the global push to regulate AI.",
                            source: ArticleSource(id: "daily", name: "The Daily"),
                            url: "https://podcasts.apple.com",
                            imageURL: "https://picsum.photos/201",
                            publishedAt: Date().addingTimeInterval(-3600),
                            mediaType: .podcast,
                            mediaURL: "https://feeds.simplecast.com/audio.mp3",
                            mediaDuration: 1823
                        )
                    ),
                    onTap: {},
                    onPlay: {},
                    onShare: {}
                )
            }
            .padding()
        }
    }
    .preferredColorScheme(.dark)
}
