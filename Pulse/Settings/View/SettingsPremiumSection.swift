import EntropyCore
import SwiftUI

struct SettingsPremiumSection: View {
    let isPremium: Bool
    let onUpgradeTapped: () -> Void

    var body: some View {
        Section {
            Button {
                if !isPremium {
                    HapticManager.shared.buttonPress()
                    onUpgradeTapped()
                }
            } label: {
                HStack(spacing: Spacing.md) {
                    premiumIcon

                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(isPremium ? Localizable.paywall.premiumActive : Localizable.paywall.goPremium)
                            .font(Typography.headlineMedium)
                            .foregroundStyle(.primary)

                        Text(isPremium ? Localizable.paywall.fullAccess : Localizable.paywall.unlockFeatures)
                            .font(Typography.captionLarge)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    trailingIcon
                }
                .padding(.vertical, Spacing.xs)
            }
            .buttonStyle(.plain)
            .disabled(isPremium)
        } header: {
            Text(String(localized: "settings.subscription"))
                .font(Typography.captionLarge)
        }
    }

    private var premiumIcon: some View {
        ZStack {
            Circle()
                .fill(isPremium ? Color.yellow.opacity(0.2) : Color.orange.opacity(0.15))
                .frame(width: 44, height: 44)

            Image(systemName: isPremium ? "crown.fill" : "crown")
                .font(.system(size: IconSize.lg))
                .foregroundStyle(isPremium ? .yellow : .orange)
        }
        .glowEffect(color: isPremium ? .yellow : .clear, radius: 8)
    }

    @ViewBuilder
    private var trailingIcon: some View {
        if isPremium {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: IconSize.lg))
                .foregroundStyle(Color.Semantic.success)
        } else {
            Image(systemName: "chevron.right")
                .font(Typography.captionLarge)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    SettingsPremiumSection(isPremium: false, onUpgradeTapped: {})
        .preferredColorScheme(.dark)
}

#Preview("Premium Active") {
    SettingsPremiumSection(isPremium: true, onUpgradeTapped: {})
        .preferredColorScheme(.dark)
}
