import SwiftUI

// MARK: - Stretchy Header

/// A header component that stays sticky at the top and stretches when pulled down.
/// Commonly used for hero images in detail views.
struct StretchyHeader<Content: View>: View {
    let baseHeight: CGFloat
    let showGradientOverlay: Bool
    let gradientHeight: CGFloat
    let content: Content

    init(
        baseHeight: CGFloat = 280,
        showGradientOverlay: Bool = true,
        gradientHeight: CGFloat = 120,
        @ViewBuilder content: () -> Content
    ) {
        self.baseHeight = baseHeight
        self.showGradientOverlay = showGradientOverlay
        self.gradientHeight = gradientHeight
        self.content = content()
    }

    var body: some View {
        GeometryReader { proxy in
            let minY = proxy.frame(in: .global).minY
            let stretchAmount = max(0, minY)
            // Ensure height never goes below baseHeight to prevent zero-dimension issues during transitions
            let height = max(baseHeight, baseHeight + stretchAmount)

            stretchyContent(height: height, width: max(1, proxy.size.width))
                .offset(y: -minY)
        }
        .frame(height: baseHeight)
        .frame(minHeight: baseHeight)
    }

    @ViewBuilder
    private func stretchyContent(height: CGFloat, width _: CGFloat) -> some View {
        GeometryReader { geo in
            let safeWidth = max(1, geo.size.width)
            let safeHeight = max(baseHeight, height)

            ZStack(alignment: .bottom) {
                content
                    .frame(width: safeWidth, height: safeHeight)
                    .clipped()

                if showGradientOverlay {
                    LinearGradient.heroOverlay
                        .frame(height: gradientHeight)
                }
            }
            .frame(width: safeWidth, height: safeHeight)
        }
        .frame(height: max(baseHeight, height))
    }
}

// MARK: - Stretchy Async Image

/// A convenience wrapper for StretchyHeader with AsyncImage content.
struct StretchyAsyncImage: View {
    let url: URL?
    let baseHeight: CGFloat
    let showGradientOverlay: Bool
    let gradientHeight: CGFloat
    let accessibilityLabel: String?

    init(
        url: URL?,
        baseHeight: CGFloat = 280,
        showGradientOverlay: Bool = true,
        gradientHeight: CGFloat = 120,
        accessibilityLabel: String? = nil
    ) {
        self.url = url
        self.baseHeight = baseHeight
        self.showGradientOverlay = showGradientOverlay
        self.gradientHeight = gradientHeight
        self.accessibilityLabel = accessibilityLabel
    }

    var body: some View {
        StretchyHeader(
            baseHeight: baseHeight,
            showGradientOverlay: showGradientOverlay,
            gradientHeight: gradientHeight
        ) {
            CachedAsyncImage(url: url, accessibilityLabel: accessibilityLabel) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Rectangle()
                    .fill(Color.primary.opacity(0.05))
                    .overlay { ProgressView() }
            }
        }
    }
}

// MARK: - Previews

#Preview("Stretchy Header") {
    ScrollView {
        VStack(spacing: 0) {
            StretchyHeader(baseHeight: 300) {
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }

            VStack(spacing: Spacing.md) {
                Text("Content Title")
                    .font(Typography.displaySmall)

                Text("This content scrolls over the stretchy header. Pull down to see the stretch effect.")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(.secondary)
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
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
    }
    .ignoresSafeArea(.container, edges: .top)
}

#Preview("Stretchy Async Image") {
    ScrollView {
        VStack(spacing: 0) {
            StretchyAsyncImage(
                url: URL(string: "https://picsum.photos/800/600"),
                baseHeight: 280
            )

            Text("Article Content")
                .font(Typography.titleLarge)
                .padding(Spacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.regularMaterial)
        }
    }
    .ignoresSafeArea(.container, edges: .top)
}
