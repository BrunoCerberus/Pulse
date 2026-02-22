import EntropyCore
import SwiftUI

// MARK: - Constants

private enum Constants {
    static var header: String {
        AppLocalization.shared.localized("applock.settings_header")
    }

    static var toggle: String {
        AppLocalization.shared.localized("applock.settings_toggle")
    }

    static var footer: String {
        AppLocalization.shared.localized("applock.settings_footer")
    }

    static var unavailable: String {
        AppLocalization.shared.localized("applock.settings_unavailable")
    }
}

// MARK: - SettingsSecuritySection

/// Settings section for enabling/disabling Face ID app lock.
struct SettingsSecuritySection: View {
    @ObservedObject var lockManager: AppLockManager

    var body: some View {
        Section {
            if lockManager.canUseBiometrics {
                Toggle(Constants.toggle, isOn: Binding(
                    get: { lockManager.isAppLockEnabled },
                    set: { newValue in
                        Task { await lockManager.toggleAppLock(enabled: newValue) }
                    }
                ))
            } else {
                HStack {
                    Text(Constants.toggle)
                    Spacer()
                    Text(Constants.unavailable)
                        .font(Typography.captionLarge)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text(Constants.header)
                .font(Typography.captionLarge)
        } footer: {
            Text(Constants.footer)
        }
    }
}

#Preview {
    SettingsSecuritySection(lockManager: .shared)
        .preferredColorScheme(.dark)
}

#Preview("Biometrics Not Available") {
    SettingsSecuritySection(lockManager: .shared)
        .preferredColorScheme(.dark)
}
