import EntropyCore
import SwiftUI

/// Root view that switches between SignIn and main app based on auth state.
///
/// This view observes the AuthenticationManager and displays:
/// - Loading state while checking authentication
/// - SignInView when user is not authenticated
/// - CoordinatorView when user is authenticated (with biometric lock overlay)
struct RootView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var appLockManager = AppLockManager.shared

    let serviceLocator: ServiceLocator

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showBiometricOptIn = false

    var body: some View {
        Group {
            switch authManager.authState {
            case .loading:
                loadingView
            case .unauthenticated:
                SignInView(serviceLocator: serviceLocator)
            case let .authenticated(user):
                ZStack {
                    CoordinatorView(serviceLocator: serviceLocator)

                    if appLockManager.isLocked {
                        AppLockView()
                            .transition(.opacity)
                    }

                    if appLockManager.isPrivacyOverlayActive {
                        Color.black
                            .ignoresSafeArea()
                            .overlay(.ultraThinMaterial)
                            .ignoresSafeArea()
                    }
                }
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: appLockManager.isLocked)
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.15), value: appLockManager.isPrivacyOverlayActive)
                .sheet(isPresented: $showBiometricOptIn, onDismiss: {
                    if appLockManager.isBiometricEnabled {
                        appLockManager.lockAndAuthenticate()
                    }
                }) {
                    BiometricOptInView()
                }
                .onAppear {
                    if appLockManager.shouldShowOptIn(for: user.uid) {
                        showBiometricOptIn = true
                    }
                }
            }
        }
        .preferredColorScheme(themeManager.colorScheme)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: authManager.authState)
    }

    private var loadingView: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ProgressView()
                .tint(.white)
                .scaleEffect(1.5)
        }
    }
}

#Preview("Authenticated") {
    RootView(serviceLocator: .preview)
}

#Preview("Unauthenticated") {
    RootView(serviceLocator: .previewUnauthenticated)
}
