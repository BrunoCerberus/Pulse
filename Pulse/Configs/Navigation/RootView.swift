import EntropyCore
import SwiftUI

/// Root view that switches between SignIn and main app based on auth state.
///
/// This view observes the AuthenticationManager and displays:
/// - Loading state while checking authentication
/// - SignInView when user is not authenticated
/// - CoordinatorView when user is authenticated
struct RootView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var lockManager = AppLockManager.shared

    let serviceLocator: ServiceLocator

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Group {
                switch authManager.authState {
                case .loading:
                    loadingView
                case .unauthenticated:
                    SignInView(serviceLocator: serviceLocator)
                case .authenticated:
                    CoordinatorView(serviceLocator: serviceLocator)
                        .onAppear { lockManager.checkPostSignupPrompt() }
                        .sheet(isPresented: $lockManager.showFaceIDPrompt) {
                            FaceIDPromptView()
                        }
                }
            }

            if lockManager.isLocked, case .authenticated = authManager.authState {
                AppLockOverlayView()
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
