import EntropyCore
import SwiftUI

// MARK: - Skeleton Views

struct FeaturedMediaCarouselSkeleton: View {
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

struct FeaturedMediaCardSkeleton: View {
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

struct MediaListSkeleton: View {
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
