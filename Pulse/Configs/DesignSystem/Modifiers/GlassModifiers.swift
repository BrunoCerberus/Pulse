import SwiftUI

// MARK: - Glass Background Modifier

struct GlassBackgroundModifier: ViewModifier {
    let style: GlassStyle
    let cornerRadius: CGFloat
    let showBorder: Bool

    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(style.material)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        showBorder ? Color.Border.adaptive(for: colorScheme) : .clear,
                        lineWidth: 0.5
                    )
            )
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

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    if isActive {
                        LinearGradient(
                            colors: [
                                .clear,
                                .white.opacity(0.4),
                                .clear,
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geometry.size.width * 2)
                        .offset(x: -geometry.size.width + phase * geometry.size.width * 3)
                        .mask(content)
                    }
                }
            )
            .onAppear {
                guard isActive else { return }
                withAnimation(
                    .linear(duration: duration)
                        .repeatForever(autoreverses: false)
                ) {
                    phase = 1
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

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(AnimationTiming.springQuick, value: configuration.isPressed)
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

    @State private var opacity: Double = 0
    @State private var offset: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .offset(y: offset)
            .onAppear {
                withAnimation(.easeOut(duration: AnimationTiming.normal).delay(delay)) {
                    opacity = 1
                    offset = 0
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

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onChange(of: trigger) { _, newValue in
                if newValue {
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
