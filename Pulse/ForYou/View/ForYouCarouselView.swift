import EntropyCore
import SwiftUI

/// Horizontal carousel of personalized articles, embedded in `HomeView`.
///
/// The view itself owns no navigation — taps are bubbled up via the
/// `onArticleTapped` callback so the host (Home) can route through its
/// existing article-detail flow. Same pattern used by Home's own breaking
/// news / recently-read carousels.
struct ForYouCarouselView: View {
    /// View-state snapshot (cards, loading, error).
    let viewState: ForYouViewState
    /// Tap handler — host wires this to its article-detail navigation.
    let onArticleTapped: (String) -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var cardWidth: CGFloat {
        // Match the `recentlyReadCardWidth` cadence on Home so the section
        // visually rhymes with the rest of the page.
        horizontalSizeClass == .regular ? 320 : 260
    }

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            verticalStack
        } else {
            horizontalCarousel
        }
    }

    // MARK: - Horizontal Carousel (default)

    private var horizontalCarousel: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: Spacing.md) {
                ForEach(viewState.cards) { card in
                    cardView(for: card)
                        .frame(width: cardWidth)
                        .fadeIn(delay: Double(card.animationIndex) * 0.05)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Vertical Stack (accessibility size)

    private var verticalStack: some View {
        VStack(spacing: Spacing.md) {
            ForEach(viewState.cards) { card in
                cardView(for: card)
                    .fadeIn(delay: Double(card.animationIndex) * 0.05)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }

    // MARK: - Single Card

    private func cardView(for card: ForYouCardItem) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            GlassArticleCardCompact(
                title: card.articleViewItem.title,
                sourceName: card.articleViewItem.sourceName,
                imageURL: card.articleViewItem.imageURL,
                onTap: { onArticleTapped(card.id) }
            )

            if !card.explanation.isEmpty {
                HStack(spacing: Spacing.xxs) {
                    Image(systemName: "sparkles")
                        .font(.system(size: IconSize.xs))
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)

                    Text("\(Constants.matchedPrefix) \(card.explanation)")
                        .font(Typography.captionMedium)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .padding(.horizontal, Spacing.sm)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(Constants.whyThis): \(card.explanation)")
            }
        }
    }
}
