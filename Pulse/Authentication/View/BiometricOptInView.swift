import EntropyCore
import SwiftUI

/// Opt-in dialog presented to users to enable biometric app lock.
///
/// Shown once per user account after sign-in. Allows enabling FaceID/TouchID
/// or dismissing to skip.
struct BiometricOptInView: View {
    @StateObject private var appLockManager = AppLockManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: Spacing.xxl) {
            Spacer()

            iconSection

            textSection

            Spacer()

            buttonsSection
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.bottom, Spacing.xxl)
        .background {
            ZStack {
                Color.black

                LinearGradient(
                    colors: [
                        Color.purple.opacity(0.3),
                        Color.blue.opacity(0.2),
                        Color.black,
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            .ignoresSafeArea()
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private var iconSection: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 100, height: 100)

            Image(systemName: appLockManager.biometricIconName)
                .font(.system(size: 40))
                .foregroundStyle(.white)
        }
    }

    private var textSection: some View {
        VStack(spacing: Spacing.sm) {
            Text("Protect Your App")
                .font(Typography.displaySmall)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text("Enable \(appLockManager.biometricName) to keep your news and data secure. You can change this anytime in Settings.")
                .font(Typography.bodyLarge)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }

    private var buttonsSection: some View {
        VStack(spacing: Spacing.md) {
            Button {
                HapticManager.shared.buttonPress()
                appLockManager.enableBiometric()
                if let uid = AuthenticationManager.shared.currentUser?.uid {
                    appLockManager.markPrompted(for: uid)
                }
                dismiss()
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: appLockManager.biometricIconName)
                        .font(.headline)

                    Text("Enable \(appLockManager.biometricName)")
                        .font(Typography.labelLarge)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.white)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
            }
            .buttonStyle(.plain)

            Button {
                HapticManager.shared.tap()
                if let uid = AuthenticationManager.shared.currentUser?.uid {
                    appLockManager.markPrompted(for: uid)
                }
                dismiss()
            } label: {
                Text("Not Now")
                    .font(Typography.labelLarge)
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    BiometricOptInView()
}
