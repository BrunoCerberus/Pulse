import EntropyCore
import SwiftUI

// MARK: - Glass Article Skeleton

struct GlassArticleSkeleton: View {
    @State private var isAnimating = false

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                SkeletonShape(width: 60, height: 12)

                SkeletonShape(height: 18)
                SkeletonShape(width: 200, height: 18)

                SkeletonShape(height: 14)
                SkeletonShape(width: 150, height: 14)

                HStack(spacing: Spacing.xs) {
                    SkeletonShape(width: 80, height: 12)
                    SkeletonShape(width: 60, height: 12)
                }
            }

            Spacer()

            SkeletonShape(width: 100, height: 100, cornerRadius: CornerRadius.sm)
        }
        .padding(Spacing.md)
        .glassBackground(style: .thin, cornerRadius: CornerRadius.lg)
        .shimmer(isActive: isAnimating)
        .onAppear {
            isAnimating = true
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Glass Hero Skeleton

struct GlassHeroSkeleton: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Full image background placeholder
            Color.primary.opacity(0.08)

            // Content overlay at bottom (matching HeroNewsCard)
            VStack(alignment: .leading, spacing: Spacing.xs) {
                // Breaking badge placeholder
                SkeletonShape(width: 80, height: 22, cornerRadius: CornerRadius.pill)

                // Title lines
                SkeletonShape(height: 18)
                SkeletonShape(width: 220, height: 18)

                // Metadata row
                HStack(spacing: Spacing.xs) {
                    SkeletonShape(width: 60, height: 12)
                    SkeletonShape(width: 80, height: 12)
                }
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial.opacity(0.5))
        }
        .frame(width: 300)
        .frame(maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous))
        .shimmer(isActive: isAnimating)
        .onAppear {
            isAnimating = true
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Glass Category Skeleton

struct GlassCategorySkeleton: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: Spacing.xs) {
            SkeletonShape(width: 40, height: 40, cornerRadius: CornerRadius.sm)
            SkeletonShape(width: 60, height: 12)
        }
        .padding(Spacing.md)
        .frame(minWidth: 100)
        .glassBackground(style: .thin, cornerRadius: CornerRadius.md)
        .shimmer(isActive: isAnimating)
        .onAppear {
            isAnimating = true
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Article List Skeleton

struct ArticleListSkeleton: View {
    let count: Int

    init(count: Int = 5) {
        self.count = count
    }

    var body: some View {
        LazyVStack(spacing: Spacing.sm) {
            ForEach(0 ..< count, id: \.self) { index in
                GlassArticleSkeleton()
                    .fadeIn(delay: Double(index) * 0.05)
            }
        }
        .padding(.horizontal, Spacing.md)
    }
}

// MARK: - Hero Carousel Skeleton

struct HeroCarouselSkeleton: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.md) {
                ForEach(0 ..< 3, id: \.self) { index in
                    GlassHeroSkeleton()
                        .fadeIn(delay: Double(index) * 0.1)
                }
            }
            .padding(.horizontal, Spacing.md)
        }
    }
}

// MARK: - Previews

#Preview("Skeletons") {
    ZStack {
        LinearGradient.meshFallback
            .ignoresSafeArea()

        ScrollView {
            VStack(spacing: Spacing.lg) {
                GlassSectionHeader("Breaking News")

                HeroCarouselSkeleton()

                GlassSectionHeader("Top Stories")

                ArticleListSkeleton(count: 3)
            }
        }
    }
    .preferredColorScheme(.dark)
}
