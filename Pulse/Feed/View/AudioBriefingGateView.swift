import EntropyCore
import SwiftUI

// MARK: - Audio Briefing Gate View

/// An inline premium gate component for the audio briefing feature.
///
/// Displays a compact upgrade prompt with the orange headphones icon,
/// shown when non-premium users have access to premium content but
/// the audio briefing is not yet available.
struct AudioBriefingGateView: View {
    private enum Constants {
        static var title: String {
            AppLocalization.localized("feed.audio_briefing_gate.title")
        }

        static var description: String {
            AppLocalization.localized("feed.audio_briefing_gate.description")
        }

        static var unlockButton: String {
            AppLocalization.localized("feed.audio_briefing_gate.unlock_button")
        }

        static var premiumHint: String {
            AppLocalization.localized("settings.premium.hint")
        }

        static var badge: String {
            AppLocalization.localized("premium_gate.badge")
        }

        static var unlockLabel: String {
            AppLocalization.localized("premium_gate.unlock_label")
        }
    }

    var onUnlockTapped: (() -> Void)?

    @State private var isPaywallPresented = false
    @StateObject private var paywallViewModel: PaywallViewModel

    init(serviceLocator: ServiceLocator, onUnlockTapped: (() -> Void)? = nil) {
        self.onUnlockTapped = onUnlockTapped
        _paywallViewModel = StateObject(wrappedValue: PaywallViewModel(serviceLocator: serviceLocator))
    }

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(
                        width: dynamicTypeSize.isAccessibilitySize ? 64 : 80,
                        height: dynamicTypeSize.isAccessibilitySize ? 64 : 80
                    )

                Circle()
                    .fill(Color.orange.gradient)
                    .frame(
                        width: dynamicTypeSize.isAccessibilitySize ? 52 : 64,
                        height: dynamicTypeSize.isAccessibilitySize ? 52 : 64
                    )

                Image(systemName: "headphones")
                    .font(.system(size: dynamicTypeSize.isAccessibilitySize ? IconSize.xl : IconSize.xxl))
                    .foregroundStyle(.white)
            }
            .glowEffect(color: .orange, radius: 16)
            .accessibilityHidden(true)

            // Content
            VStack(spacing: Spacing.sm) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: IconSize.sm))
                    Text(Constants.badge)
                        .font(Typography.labelMedium)
                }
                .foregroundStyle(Color.Accent.warmGradient)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)
                .background(Color.orange.opacity(0.15))
                .clipShape(Capsule())
                .accessibilityHidden(true)

                Text(Constants.title)
                    .font(Typography.headlineMedium)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                Text(Constants.description)
                    .font(Typography.bodyMedium)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)
            }

            // Unlock Button
            Button {
                HapticManager.shared.buttonPress()
                onUnlockTapped?()
                isPaywallPresented = true
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "lock.open.fill")
                    Text(Constants.unlockButton)
                }
                .font(Typography.labelLarge)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(Color.Accent.warmGradient)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
                .shadow(color: Color.orange.opacity(0.3), radius: 8, y: 4)
            }
            .pressEffect()
            .accessibilityLabel(String(format: Constants.unlockLabel, Constants.title))
            .accessibilityHint(Constants.premiumHint)
        }
        .padding(.horizontal, Spacing.xl)
        .sheet(isPresented: $isPaywallPresented) {
            PaywallView(viewModel: paywallViewModel)
        }
    }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
}

// MARK: - Preview

#Preview {
    AudioBriefingGateView(
        serviceLocator: .preview
    )
    .preferredColorScheme(.dark)
}
