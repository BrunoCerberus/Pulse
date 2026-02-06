import EntropyCore
import SwiftUI

/// Lock screen shown when biometric authentication is required.
///
/// Displays the app logo with biometric unlock and passcode fallback buttons.
/// Auto-triggers biometric prompt on appear.
struct AppLockView: View {
    @StateObject private var appLockManager = AppLockManager.shared
    @State private var isAuthenticating = false

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: Spacing.xxl) {
                Spacer()

                logoSection

                Spacer()

                buttonsSection
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.xxl)
        }
        .task {
            await performBiometricAuth()
        }
    }

    private var backgroundGradient: some View {
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
    }

    private var logoSection: some View {
        VStack(spacing: Spacing.lg) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 100, height: 100)

                Image(systemName: "newspaper.fill")
                    .font(.title)
                    .foregroundStyle(.white)
            }

            VStack(spacing: Spacing.xs) {
                Text("Pulse")
                    .font(Typography.displayLarge)
                    .foregroundStyle(.white)

                Text("Tap to unlock")
                    .font(Typography.bodyLarge)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }

    private var buttonsSection: some View {
        VStack(spacing: Spacing.md) {
            // Primary biometric unlock button
            Button {
                HapticManager.shared.buttonPress()
                Task { await performBiometricAuth() }
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: appLockManager.biometricIconName)
                        .font(.headline)

                    Text("Unlock with \(appLockManager.biometricName)")
                        .font(Typography.labelLarge)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.white)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
            }
            .buttonStyle(.plain)
            .disabled(isAuthenticating)

            // Passcode fallback button
            Button {
                HapticManager.shared.buttonPress()
                Task { await performPasscodeAuth() }
            } label: {
                Text("Use Passcode")
                    .font(Typography.labelLarge)
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
            .buttonStyle(.plain)
            .disabled(isAuthenticating)
        }
    }

    private func performBiometricAuth() async {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        _ = await appLockManager.authenticate()
        isAuthenticating = false
    }

    private func performPasscodeAuth() async {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        _ = await appLockManager.authenticateWithPasscode()
        isAuthenticating = false
    }
}

#Preview {
    AppLockView()
}
