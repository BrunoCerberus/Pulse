import EntropyCore
import SwiftUI

// MARK: - Hero News Card

struct HeroNewsCard: View {
    let item: ArticleViewItem
    var cardWidth: CGFloat = 300
    let onTap: () -> Void

    @State private var isPulsing = false
    @State private var hasStartedPulsing = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var cardHeight: CGFloat {
        cardWidth * (200.0 / 300.0)
    }

    var body: some View {
        Button {
            HapticManager.shared.tap()
            onTap()
        } label: {
            ZStack(alignment: .bottomLeading) {
                imageBackground

                LinearGradient.heroOverlay

                contentOverlay
            }
            .frame(width: cardWidth, height: cardHeight)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                    .stroke(Color.Border.glass, lineWidth: 0.5)
            )
            .depthShadow(.elevated)
        }
        .pressEffect()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(format: AppLocalization.shared.localized("breaking_news.accessibility_label"), item.title, item.sourceName, item.formattedDate))
        .accessibilityHint(AppLocalization.shared.localized("accessibility.read_article"))
        .onAppear {
            startPulseAnimation()
        }
        .onDisappear {
            stopPulseAnimation()
        }
    }

    @ViewBuilder
    private var imageBackground: some View {
        // Use heroImageURL for hero cards (higher resolution)
        if let imageURL = item.heroImageURL ?? item.imageURL {
            CachedAsyncImage(url: imageURL, accessibilityLabel: item.title) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: cardWidth, height: cardHeight)
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
                    Image(systemName: "newspaper.fill")
                        .font(.system(size: IconSize.xxl))
                        .foregroundStyle(.white.opacity(0.5))
                }
        }
    }

    private var placeholderBackground: some View {
        LinearGradient(
            colors: [
                Color.purple.opacity(0.6),
                Color.blue.opacity(0.4),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var contentOverlay: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Spacer()

            breakingBadge

            Text(item.title)
                .font(Typography.headlineLarge)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .lineLimit(3)
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

    private var breakingBadge: some View {
        HStack(spacing: Spacing.xxs) {
            Circle()
                .fill(.white)
                .frame(width: 6, height: 6)
                .scaleEffect(isPulsing ? 1.2 : 1.0)
                .opacity(isPulsing ? 0.5 : 1.0)

            Text(AppLocalization.shared.localized("home.breaking"))
                .font(Typography.labelSmall)
                .fontWeight(.bold)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, Spacing.xxs)
        .background(
            Capsule()
                .fill(.red)
        )
        .glowEffect(color: .red, radius: isPulsing ? 8 : 4)
    }

    private var metadataRow: some View {
        HStack(spacing: Spacing.xs) {
            Text(item.sourceName)
                .font(Typography.captionMedium)
                .fontWeight(.medium)

            Circle()
                .fill(.white.opacity(0.6))
                .frame(width: 3, height: 3)
                .accessibilityHidden(true)

            Text(item.formattedDate)
                .font(Typography.captionMedium)
        }
        .foregroundStyle(.white.opacity(0.9))
    }

    private func startPulseAnimation() {
        guard !hasStartedPulsing else { return }
        hasStartedPulsing = true
        if reduceMotion {
            isPulsing = false
        } else {
            withAnimation(
                .easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true)
            ) {
                isPulsing = true
            }
        }
    }

    private func stopPulseAnimation() {
        if reduceMotion {
            isPulsing = false
        } else {
            withAnimation(.linear(duration: 0.1)) {
                isPulsing = false
            }
        }
        hasStartedPulsing = false
    }
}

// MARK: - Featured Article Card (Larger variant)

struct FeaturedArticleCard: View {
    let item: ArticleViewItem
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button {
            HapticManager.shared.tap()
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                imageSection
                    .frame(height: 180)

                contentSection
            }
            .glassBackground(style: .thin, cornerRadius: CornerRadius.lg)
            .depthShadow(.medium)
        }
        .pressEffect()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(format: AppLocalization.shared.localized("article_row.accessibility_label"), item.title, item.sourceName, item.formattedDate))
        .accessibilityHint(AppLocalization.shared.localized("accessibility.read_article"))
    }

    @ViewBuilder
    private var imageSection: some View {
        // Use heroImageURL for featured cards (higher resolution)
        if let imageURL = item.heroImageURL ?? item.imageURL {
            CachedAsyncImage(url: imageURL, accessibilityLabel: item.title) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 180)
                    .clipped()
            } placeholder: {
                Color.primary.opacity(0.05)
                    .frame(height: 180)
            }
        } else {
            Color.primary.opacity(0.05)
                .frame(height: 180)
        }
    }

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            if let category = item.category {
                GlassCategoryChip(category: category, style: .small)
            }

            Text(item.title)
                .font(Typography.titleSmall)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            if let description = item.description {
                Text(description)
                    .font(Typography.bodySmall)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

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
        .padding(Spacing.md)
    }
}

// MARK: - Previews

#Preview("Hero News Card") {
    ZStack {
        LinearGradient.meshFallback
            .ignoresSafeArea()

        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.md) {
                HeroNewsCard(
                    item: ArticleViewItem(
                        from: Article(
                            title: "Breaking: Major Climate Summit Reaches Historic Agreement",
                            source: ArticleSource(id: nil, name: "Reuters"),
                            url: "https://example.com",
                            imageURL: "https://picsum.photos/400/300",
                            publishedAt: Date()
                        )
                    ),
                    onTap: {}
                )

                HeroNewsCard(
                    item: ArticleViewItem(
                        from: Article(
                            title: "Tech Giants Face New Regulations",
                            source: ArticleSource(id: nil, name: "TechCrunch"),
                            url: "https://example.com",
                            imageURL: nil,
                            publishedAt: Date()
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
