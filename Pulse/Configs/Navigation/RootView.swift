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

    let serviceLocator: ServiceLocator

    var body: some View {
        Group {
            switch authManager.authState {
            case .loading:
                loadingView
            case .unauthenticated:
                SignInView(serviceLocator: serviceLocator)
            case .authenticated:
                CoordinatorView(serviceLocator: serviceLocator)
            }
        }
        .preferredColorScheme(themeManager.colorScheme)
        .animation(.easeInOut(duration: 0.3), value: authManager.authState)
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
