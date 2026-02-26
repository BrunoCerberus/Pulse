//
//  PremiumGateView.swift
//  Pulse
//
//  Premium feature gate component that displays an upsell overlay
//  for non-premium users attempting to access premium features.
//

import EntropyCore
import SwiftUI

// MARK: - Premium Feature Type

/// Defines the premium features that can be gated.
enum PremiumFeature {
    case dailyDigest
    case articleSummarization

    var icon: String {
        switch self {
        case .dailyDigest:
            return "sparkles"
        case .articleSummarization:
            return "doc.text.magnifyingglass"
        }
    }

    var iconColor: Color {
        switch self {
        case .dailyDigest:
            return .purple
        case .articleSummarization:
            return .blue
        }
    }

    var title: String {
        switch self {
        case .dailyDigest:
            return AppLocalization.shared.localized("premium_gate.daily_digest.title")
        case .articleSummarization:
            return AppLocalization.shared.localized("premium_gate.summarization.title")
        }
    }

    var description: String {
        switch self {
        case .dailyDigest:
            return AppLocalization.shared.localized("premium_gate.daily_digest.description")
        case .articleSummarization:
            return AppLocalization.shared.localized("premium_gate.summarization.description")
        }
    }
}

// MARK: - Premium Gate View

/// A view that gates premium content and shows an upsell when the user is not premium.
struct PremiumGateView: View {
    let feature: PremiumFeature
    let serviceLocator: ServiceLocator
    var onUnlockTapped: (() -> Void)?

    @State private var isPaywallPresented = false
    @StateObject private var paywallViewModel: PaywallViewModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(
        feature: PremiumFeature,
        serviceLocator: ServiceLocator,
        onUnlockTapped: (() -> Void)? = nil
    ) {
        self.feature = feature
        self.serviceLocator = serviceLocator
        self.onUnlockTapped = onUnlockTapped
        _paywallViewModel = StateObject(wrappedValue: PaywallViewModel(serviceLocator: serviceLocator))
    }

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // Premium Icon
            ZStack {
                let outerSize: CGFloat = dynamicTypeSize.isAccessibilitySize ? 80 : 120
                let innerSize: CGFloat = dynamicTypeSize.isAccessibilitySize ? 64 : 100

                Circle()
                    .fill(feature.iconColor.opacity(0.15))
                    .frame(width: outerSize, height: outerSize)

                Circle()
                    .fill(feature.iconColor.gradient)
                    .frame(width: innerSize, height: innerSize)

                Image(systemName: feature.icon)
                    .font(.system(size: dynamicTypeSize.isAccessibilitySize ? IconSize.xl : IconSize.xxl))
                    .foregroundStyle(.white)
            }
            .glowEffect(color: feature.iconColor, radius: 20)
            .accessibilityHidden(true)

            // Content
            VStack(spacing: Spacing.md) {
                // Premium Badge
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: IconSize.sm))
                    Text(AppLocalization.shared.localized("premium_gate.badge"))
                        .font(Typography.labelMedium)
                }
                .foregroundStyle(Color.Accent.warmGradient)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)
                .background(Color.orange.opacity(0.15))
                .clipShape(Capsule())
                .accessibilityHidden(true)

                Text(feature.title)
                    .font(Typography.displaySmall)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                Text(feature.description)
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
                    Text(AppLocalization.shared.localized("premium_gate.unlock_button"))
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
            .padding(.horizontal, Spacing.xl)
            .accessibilityLabel({
                let format = AppLocalization.shared.localized("premium_gate.unlock_label")
                return String(format: format, feature.title)
            }())
            .accessibilityHint(AppLocalization.shared.localized("settings.premium.hint"))
            .accessibilityIdentifier("unlockPremiumButton")

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LinearGradient.subtleBackground)
        .sheet(isPresented: $isPaywallPresented) {
            PaywallView(viewModel: paywallViewModel)
        }
    }
}

// MARK: - Preview

#Preview {
    PremiumGateView(
        feature: .dailyDigest,
        serviceLocator: .preview
    )
    .preferredColorScheme(.dark)
}

#Preview("Summarization Gate") {
    PremiumGateView(
        feature: .articleSummarization,
        serviceLocator: .preview
    )
    .preferredColorScheme(.dark)
}
