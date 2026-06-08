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
    @StateObject private var appLocalization = AppLocalization.shared
    @AppStorage("pulse.hasCompletedOnboarding") private var hasCompletedOnboarding = false

    let serviceLocator: ServiceLocator

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            Group {
                switch authManager.authState {
                case .loading:
                    loadingView
                case .unauthenticated:
                    SignInView(serviceLocator: serviceLocator)
                case .authenticated:
                    if hasCompletedOnboarding || TestEnvironment.isUITesting {
                        CoordinatorView(serviceLocator: serviceLocator)
                            .onAppear { lockManager.checkPostSignupPrompt() }
                            .sheet(isPresented: $lockManager.showFaceIDPrompt) {
                                FaceIDPromptView()
                            }
                    } else {
                        OnboardingView(viewModel: OnboardingViewModel(serviceLocator: serviceLocator))
                    }
                }
            }

            if lockManager.isLocked, case .authenticated = authManager.authState {
                AppLockOverlayView()
            }

            // Privacy overlay for the app-switcher snapshot. iOS captures the
            // window image immediately after `sceneWillResignActive`, so we hide
            // content the moment the scene leaves the active phase. Skipped
            // during biometry prompts (which also flip the phase to `.inactive`)
            // so users don't see a black flash mid-Face-ID — `isAuthenticating`
            // is true for that whole window.
            if shouldShowPrivacyOverlay {
                privacyOverlay
                    .transition(.identity) // no fade — must be instant before snapshot
            }
        }
        .environment(\.locale, appLocalization.locale)
        .preferredColorScheme(themeManager.colorScheme)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: authManager.authState)
    }

    private var shouldShowPrivacyOverlay: Bool {
        Self.shouldShowPrivacyOverlay(
            authState: authManager.authState,
            scenePhase: scenePhase,
            isAppLockEnabled: lockManager.isAppLockEnabled,
            isAuthenticating: lockManager.isAuthenticating
        )
    }

    /// Pure-function decision for the app-switcher privacy overlay.
    ///
    /// Extracted from the SwiftUI `body` so it can be unit-tested without
    /// driving real singletons (`AppLockManager.shared`, `AuthenticationManager.shared`)
    /// or the `Environment(\.scenePhase)` machinery.
    ///
    /// Rules:
    /// - Only users who explicitly enabled App Lock opted into privacy.
    ///   Without this gate, every notification banner / Control Center pull /
    ///   Share Sheet would flash a black overlay over the article —
    ///   `scenePhase` goes `.inactive` for many transient interactions, not
    ///   just the app-switcher snapshot.
    /// - We deliberately keep the opaque overlay visible *even when locked*:
    ///   `AppLockOverlayView` uses `.ultraThickMaterial`, which is translucent,
    ///   so the article / history underneath would still bleed through into
    ///   the snapshot. Layering the opaque overlay on top of the lock overlay
    ///   for non-active scenes seals that gap.
    /// - Suppress during biometry prompts; those flip `scenePhase` but we
    ///   want the user to see Face ID land on the actual UI rather than a
    ///   black flash.
    static func shouldShowPrivacyOverlay(
        authState: AuthenticationManager.AuthState,
        scenePhase: ScenePhase,
        isAppLockEnabled: Bool,
        isAuthenticating: Bool
    ) -> Bool {
        guard isAppLockEnabled else { return false }
        guard case .authenticated = authState else { return false }
        guard scenePhase != .active else { return false }
        if isAuthenticating { return false }
        return true
    }

    private var privacyOverlay: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Image(systemName: "lock.fill")
                .font(.system(size: 64))
                .foregroundStyle(.white.opacity(0.4))
                .accessibilityHidden(true)
        }
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
        .preferredColorScheme(.dark)
}

#Preview("Unauthenticated") {
    RootView(serviceLocator: .previewUnauthenticated)
        .preferredColorScheme(.dark)
}
