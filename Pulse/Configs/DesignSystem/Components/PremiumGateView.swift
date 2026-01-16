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
    case forYouFeed

    var icon: String {
        switch self {
        case .dailyDigest:
            return "sparkles"
        case .articleSummarization:
            return "doc.text.magnifyingglass"
        case .forYouFeed:
            return "heart.text.square.fill"
        }
    }

    var iconColor: Color {
        switch self {
        case .dailyDigest:
            return .purple
        case .articleSummarization:
            return .blue
        case .forYouFeed:
            return .orange
        }
    }

    var title: String {
        switch self {
        case .dailyDigest:
            return String(localized: "premium_gate.daily_digest.title")
        case .articleSummarization:
            return String(localized: "premium_gate.summarization.title")
        case .forYouFeed:
            return String(localized: "premium_gate.for_you.title")
        }
    }

    var description: String {
        switch self {
        case .dailyDigest:
            return String(localized: "premium_gate.daily_digest.description")
        case .articleSummarization:
            return String(localized: "premium_gate.summarization.description")
        case .forYouFeed:
            return String(localized: "premium_gate.for_you.description")
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
    @State private var isPremium = false
    @StateObject private var paywallViewModel: PaywallViewModel

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
                Circle()
                    .fill(feature.iconColor.opacity(0.15))
                    .frame(width: 120, height: 120)

                Circle()
                    .fill(feature.iconColor.gradient)
                    .frame(width: 100, height: 100)

                Image(systemName: feature.icon)
                    .font(.system(size: IconSize.xxl))
                    .foregroundStyle(.white)
            }
            .glowEffect(color: feature.iconColor, radius: 20)

            // Content
            VStack(spacing: Spacing.md) {
                // Premium Badge
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: IconSize.sm))
                    Text(String(localized: "premium_gate.badge"))
                        .font(Typography.labelMedium)
                }
                .foregroundStyle(Color.Accent.warmGradient)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)
                .background(Color.orange.opacity(0.15))
                .clipShape(Capsule())

                Text(feature.title)
                    .font(Typography.displaySmall)
                    .multilineTextAlignment(.center)

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
                    Text(String(localized: "premium_gate.unlock_button"))
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

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LinearGradient.subtleBackground)
        .onAppear {
            checkPremiumStatus()
        }
        .sheet(
            isPresented: $isPaywallPresented,
            onDismiss: { checkPremiumStatus() },
            content: { PaywallView(viewModel: paywallViewModel) }
        )
    }

    private func checkPremiumStatus() {
        do {
            let storeKitService = try serviceLocator.retrieve(StoreKitService.self)
            isPremium = storeKitService.isPremium
        } catch {
            isPremium = false
        }
    }
}

// MARK: - Premium Gated Modifier

/// A view modifier that conditionally shows premium content or a gate.
struct PremiumGatedModifier<GateContent: View>: ViewModifier {
    let isPremium: Bool
    let gateContent: GateContent

    init(isPremium: Bool, @ViewBuilder gateContent: () -> GateContent) {
        self.isPremium = isPremium
        self.gateContent = gateContent()
    }

    func body(content: Content) -> some View {
        if isPremium {
            content
        } else {
            gateContent
        }
    }
}

extension View {
    /// Conditionally shows this view if premium, otherwise shows the gate content.
    func premiumGated<GateContent: View>(
        isPremium: Bool,
        @ViewBuilder gateContent: () -> GateContent
    ) -> some View {
        modifier(PremiumGatedModifier(isPremium: isPremium, gateContent: gateContent))
    }
}

// MARK: - Preview

#Preview {
    PremiumGateView(
        feature: .dailyDigest,
        serviceLocator: .preview
    )
}

#Preview("For You Gate") {
    PremiumGateView(
        feature: .forYouFeed,
        serviceLocator: .preview
    )
}

#Preview("Summarization Gate") {
    PremiumGateView(
        feature: .articleSummarization,
        serviceLocator: .preview
    )
}
