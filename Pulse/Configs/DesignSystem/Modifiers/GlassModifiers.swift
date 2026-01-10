import SwiftUI

// MARK: - Glass Background Modifier

struct GlassBackgroundModifier: ViewModifier {
    let style: GlassStyle
    let cornerRadius: CGFloat
    let showBorder: Bool

    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        showBorder ? Color.Border.adaptive(for: colorScheme) : .clear,
                        lineWidth: 0.5
                    )
            )
    }

    @ViewBuilder
    private var backgroundView: some View {
        if style.usesMaterial {
            Rectangle().fill(style.material)
        } else {
            // Solid background for performance - no blur
            Color(uiColor: colorScheme == .dark ? .secondarySystemBackground : .systemBackground)
        }
    }
}

extension View {
    func glassBackground(
        style: GlassStyle = .regular,
        cornerRadius: CGFloat = CornerRadius.lg,
        showBorder: Bool = true
    ) -> some View {
        modifier(GlassBackgroundModifier(style: style, cornerRadius: cornerRadius, showBorder: showBorder))
    }
}

// MARK: - Depth Shadow Modifier

struct DepthShadowModifier: ViewModifier {
    let style: ShadowStyle

    func body(content: Content) -> some View {
        content
            .shadow(
                color: style.color,
                radius: style.radius,
                x: style.xOffset,
                y: style.yOffset
            )
    }
}

extension View {
    func depthShadow(_ style: ShadowStyle) -> some View {
        modifier(DepthShadowModifier(style: style))
    }
}

// MARK: - Shimmer Modifier

struct ShimmerModifier: ViewModifier {
    let isActive: Bool
    let duration: Double

    @State private var phase: CGFloat = 0
    @State private var isAnimating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .overlay(
                shimmerOverlay
                    .allowsHitTesting(false)
            )
            .clipped()
            .onAppear {
                guard isActive, !isAnimating else { return }
                isAnimating = true
                if !reduceMotion {
                    withAnimation(
                        .linear(duration: duration)
                            .repeatForever(autoreverses: false)
                    ) {
                        phase = 1
                    }
                }
            }
            .onDisappear {
                if !reduceMotion {
                    withAnimation(.linear(duration: 0.1)) {
                        phase = 0
                    }
                }
                isAnimating = false
            }
    }

    @ViewBuilder
    private var shimmerOverlay: some View {
        if isActive, isAnimating {
            GeometryReader { geometry in
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.3),
                        .clear,
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: geometry.size.width)
                .offset(x: -geometry.size.width + phase * geometry.size.width * 2)
                .blendMode(.softLight)
            }
        }
    }
}

extension View {
    func shimmer(isActive: Bool = true, duration: Double = AnimationTiming.shimmer) -> some View {
        modifier(ShimmerModifier(isActive: isActive, duration: duration))
    }
}

// MARK: - Press Effect Button Style

/// A button style that provides a subtle scale effect on press.
/// This approach works properly with ScrollView unlike gesture-based solutions.
struct PressEffectButtonStyle: ButtonStyle {
    let scale: CGFloat
    let enableHaptic: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(reduceMotion ? nil : AnimationTiming.springQuick, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed && enableHaptic {
                    HapticManager.shared.cardPress()
                }
            }
    }
}

extension View {
    /// Applies a press effect using a custom ButtonStyle.
    /// Note: This only works when applied to Button views.
    /// For non-Button views, use `pressEffectGesture()` instead.
    func pressEffect(scale: CGFloat = 0.97, enableHaptic: Bool = true) -> some View {
        buttonStyle(PressEffectButtonStyle(scale: scale, enableHaptic: enableHaptic))
    }
}

// MARK: - Glow Effect Modifier

struct GlowEffectModifier: ViewModifier {
    let color: Color
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.5), radius: radius / 2)
            .shadow(color: color.opacity(0.3), radius: radius)
    }
}

extension View {
    func glowEffect(color: Color, radius: CGFloat = 8) -> some View {
        modifier(GlowEffectModifier(color: color, radius: radius))
    }
}

// MARK: - Parallax Effect Modifier

struct ParallaxEffectModifier: ViewModifier {
    let offset: CGFloat
    let multiplier: CGFloat

    func body(content: Content) -> some View {
        content
            .offset(y: offset * multiplier)
    }
}

extension View {
    func parallaxEffect(offset: CGFloat, multiplier: CGFloat = 0.3) -> some View {
        modifier(ParallaxEffectModifier(offset: offset, multiplier: multiplier))
    }
}

// MARK: - Fade In Modifier

struct FadeInModifier: ViewModifier {
    let delay: Double

    @State private var hasAnimated = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Cap delay to prevent excessive animation queuing
    private static let maxDelay: Double = 0.3

    func body(content: Content) -> some View {
        content
            .opacity(hasAnimated ? 1 : 0)
            .offset(y: hasAnimated ? 0 : (reduceMotion ? 0 : 20))
            .onAppear {
                guard !hasAnimated else { return }

                // Skip animation for reduce motion preference
                if reduceMotion {
                    hasAnimated = true
                    return
                }

                // Cap delay but still animate all items on first appearance
                let cappedDelay = min(delay, Self.maxDelay)
                withAnimation(.easeOut(duration: AnimationTiming.normal).delay(cappedDelay)) {
                    hasAnimated = true
                }
            }
    }
}

extension View {
    func fadeIn(delay: Double = 0) -> some View {
        modifier(FadeInModifier(delay: delay))
    }
}

// MARK: - Bounce Effect Modifier

struct BounceEffectModifier: ViewModifier {
    @Binding var trigger: Bool

    @State private var scale: CGFloat = 1.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onChange(of: trigger) { _, newValue in
                if newValue {
                    if reduceMotion {
                        scale = 1.2
                        scale = 1.0
                    } else {
                        withAnimation(AnimationTiming.springBouncy) {
                            scale = 1.2
                        }
                        withAnimation(AnimationTiming.springBouncy.delay(0.1)) {
                            scale = 1.0
                        }
                    }
                }
            }
    }
}

extension View {
    func bounceEffect(trigger: Binding<Bool>) -> some View {
        modifier(BounceEffectModifier(trigger: trigger))
    }
}

// MARK: - Reduced Motion Support

extension View {
    @ViewBuilder
    func animationConditional<V: Equatable>(_ animation: Animation?, value: V) -> some View {
        if UIAccessibility.isReduceMotionEnabled {
            self
        } else {
            self.animation(animation, value: value)
        }
    }
}
