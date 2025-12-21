import SwiftUI

// MARK: - Glass Card

struct GlassCard<Content: View>: View {
    let content: Content
    var style: GlassStyle
    var cornerRadius: CGFloat
    var shadowStyle: ShadowStyle
    var showBorder: Bool
    var padding: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    init(
        style: GlassStyle = .regular,
        cornerRadius: CGFloat = CornerRadius.lg,
        shadowStyle: ShadowStyle = .medium,
        showBorder: Bool = true,
        padding: CGFloat = Spacing.md,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.style = style
        self.cornerRadius = cornerRadius
        self.shadowStyle = shadowStyle
        self.showBorder = showBorder
        self.padding = padding
    }

    var body: some View {
        content
            .padding(padding)
            .background(style.material)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        showBorder ? Color.Border.adaptive(for: colorScheme) : .clear,
                        lineWidth: 0.5
                    )
            )
            .depthShadow(shadowStyle)
    }
}

// MARK: - Glass Card Button

struct GlassCardButton<Content: View>: View {
    let content: Content
    let action: () -> Void
    var style: GlassStyle
    var cornerRadius: CGFloat
    var shadowStyle: ShadowStyle
    var showBorder: Bool
    var padding: CGFloat
    var enableHaptic: Bool

    @Environment(\.colorScheme) private var colorScheme

    init(
        style: GlassStyle = .regular,
        cornerRadius: CGFloat = CornerRadius.lg,
        shadowStyle: ShadowStyle = .medium,
        showBorder: Bool = true,
        padding: CGFloat = Spacing.md,
        enableHaptic: Bool = true,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.action = action
        self.style = style
        self.cornerRadius = cornerRadius
        self.shadowStyle = shadowStyle
        self.showBorder = showBorder
        self.padding = padding
        self.enableHaptic = enableHaptic
    }

    var body: some View {
        Button(
            action: {
                if enableHaptic {
                    HapticManager.shared.tap()
                }
                action()
            },
            label: {
                content
                    .padding(padding)
                    .background(style.material)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(
                                showBorder ? Color.Border.adaptive(for: colorScheme) : .clear,
                                lineWidth: 0.5
                            )
                    )
                    .depthShadow(shadowStyle)
            }
        )
        .buttonStyle(.plain)
        .pressEffect(enableHaptic: false)
    }
}

// MARK: - Glass Container (Full Width)

struct GlassContainer<Content: View>: View {
    let content: Content
    var style: GlassStyle
    var padding: EdgeInsets

    @Environment(\.colorScheme) private var colorScheme

    init(
        style: GlassStyle = .thin,
        padding: EdgeInsets = EdgeInsets(
            top: Spacing.md,
            leading: Spacing.md,
            bottom: Spacing.md,
            trailing: Spacing.md
        ),
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.style = style
        self.padding = padding
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity)
            .background(style.material)
            .overlay(
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color.Border.adaptive(for: colorScheme)),
                alignment: .bottom
            )
    }
}

// MARK: - Previews

#Preview("Glass Card") {
    ZStack {
        LinearGradient.meshFallback
            .ignoresSafeArea()

        VStack(spacing: Spacing.lg) {
            GlassCard {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Glass Card")
                        .font(Typography.titleMedium)
                    Text("This is a glassmorphism styled card with blur effect.")
                        .font(Typography.bodyMedium)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GlassCardButton(
                action: {},
                content: {
                    HStack {
                        Image(systemName: "star.fill")
                        Text("Tap Me")
                            .font(Typography.labelLarge)
                    }
                    .frame(maxWidth: .infinity)
                }
            )

            GlassCard(style: .ultraThin, shadowStyle: .subtle) {
                Text("Ultra Thin Style")
                    .font(Typography.bodyMedium)
            }
        }
        .padding()
    }
}
