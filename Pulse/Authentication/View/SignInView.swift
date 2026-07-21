import AuthenticationServices
import EntropyCore
import SwiftUI

// MARK: - SignInView

struct SignInView: View {
    @StateObject private var viewModel: SignInViewModel
    @State private var showError = false
    /// Partial-cleanup failure message persisted by `SettingsViewModel`
    /// across the sign-out / delete-account auth-state flip. `SignInView`
    /// is the next surface the user sees, so this is where we present
    /// the error that `SettingsView` couldn't (it had already been
    /// dismounted by `RootView` swapping to `SignInView`).
    @State private var pendingCleanupError: String?

    init(serviceLocator: ServiceLocator) {
        _viewModel = StateObject(wrappedValue: SignInViewModel(serviceLocator: serviceLocator))
    }

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: Spacing.xxl) {
                Spacer()

                logoSection

                Spacer()

                signInButtonsSection

                termsSection
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.xxl)

            if viewModel.viewState.isLoading {
                loadingOverlay
            }
        }
        .alert(Constants.error, isPresented: $showError) {
            Button(Constants.okButton) {
                viewModel.handle(event: .onDismissError)
            }
        } message: {
            Text(viewModel.viewState.errorMessage ?? Constants.unknownError)
        }
        .onChange(of: viewModel.viewState.errorMessage) { _, newValue in
            showError = newValue != nil
        }
        .alert(
            Constants.error,
            isPresented: Binding(
                get: { pendingCleanupError != nil },
                set: {
                    if !$0 {
                        dismissPendingCleanupError()
                    }
                },
            ),
        ) {
            Button(Constants.okButton) { dismissPendingCleanupError() }
        } message: {
            Text(pendingCleanupError ?? "")
        }
        .onAppear { loadPendingCleanupError() }
    }

    private func loadPendingCleanupError() {
        let defaults = UserDefaults.standard
        if let message = defaults.string(forKey: SettingsViewModel.pendingCleanupErrorKey),
           !message.isEmpty
        {
            pendingCleanupError = message
        }
    }

    private func dismissPendingCleanupError() {
        UserDefaults.standard.removeObject(forKey: SettingsViewModel.pendingCleanupErrorKey)
        pendingCleanupError = nil
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
                endPoint: .bottomTrailing,
            )
        }
    }

    private var logoSection: some View {
        VStack(spacing: Spacing.lg) {
            ZStack {
                Circle()
                    .frame(width: 100, height: 100)
                    .glassEffect(.regular, in: .circle)

                Image(systemName: "newspaper.fill")
                    .font(.title)
                    .foregroundStyle(.white)
            }
            .glowEffect(color: Color.Accent.primary, radius: 20)
            .accessibilityHidden(true)
            // Hidden reviewer entry: 5 quick taps on the logo trigger an
            // anonymous Firebase sign-in so App Review can reach auth-gated
            // screens without shared OAuth credentials. Trigger is documented
            // in App Store Connect → App Review Information.
            .onTapGesture(count: 5) {
                HapticManager.shared.success()
                viewModel.handle(event: .onReviewerSignInTriggered)
            }

            VStack(spacing: Spacing.xs) {
                Text(Constants.appName)
                    .font(Typography.displayLarge)
                    .foregroundStyle(.white)

                Text(Constants.tagline)
                    .font(Typography.bodyLarge)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }

    private var signInButtonsSection: some View {
        VStack(spacing: Spacing.md) {
            // Sign in with Apple — Apple-provided button satisfies HIG 4.8 /
            // App Review guidelines; custom buttons can trigger rejection.
            AppleSignInButton {
                HapticManager.shared.buttonPress()
                viewModel.handle(event: .onAppleSignInTapped)
            }
            .frame(height: 50)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
            .accessibilityLabel(Constants.signInApple)
            .accessibilityHint(Constants.appleHint)

            // Sign in with Google
            Button {
                HapticManager.shared.buttonPress()
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let viewController = windowScene.windows.first?.rootViewController
                {
                    viewModel.handle(event: .onGoogleSignInTapped(viewController))
                }
            } label: {
                HStack(spacing: Spacing.sm) {
                    googleLogo
                        .frame(width: 20, height: 20)

                    Text(Constants.signInGoogle)
                        .font(Typography.labelLarge)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.white)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Constants.signInGoogle)
            .accessibilityHint(Constants.googleHint)
        }
    }

    private var googleLogo: some View {
        // Google "G" logo using SF Symbol as fallback
        // In production, add a google_logo image to Assets
        Image(systemName: "g.circle.fill")
            .font(.headline)
            .foregroundStyle(
                .linearGradient(
                    colors: [.red, .yellow, .green, .blue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing,
                ),
            )
    }

    private var termsSection: some View {
        Text(termsAttributedString)
            .font(Typography.captionMedium)
            .foregroundStyle(.white.opacity(0.7))
            .multilineTextAlignment(.center)
            .tint(.white)
            .accessibilityElement(children: .contain)
    }

    private var termsAttributedString: AttributedString {
        let formatted = String(
            format: Constants.termsMarkdownFormat,
            LegalURLs.termsOfService.absoluteString,
            LegalURLs.privacyPolicy.absoluteString,
        )
        if let attributed = try? AttributedString(markdown: formatted) {
            return attributed
        }
        return AttributedString(Constants.terms)
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: Spacing.md) {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)

                Text(Constants.signingIn)
                    .font(Typography.bodyMedium)
                    .foregroundStyle(.white)
            }
            .padding(Spacing.xl)
            .glassEffect(.regular, in: .rect(cornerRadius: CornerRadius.lg))
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Constants.signingIn)
        }
    }
}

// MARK: - AppleSignInButton

/// SwiftUI wrapper around `ASAuthorizationAppleIDButton`. App Review requires
/// the Apple-provided control rather than a custom-styled button.
private struct AppleSignInButton: UIViewRepresentable {
    let action: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }

    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(type: .signIn, style: .white)
        button.addTarget(context.coordinator, action: #selector(Coordinator.handleTap), for: .touchUpInside)
        return button
    }

    func updateUIView(_: ASAuthorizationAppleIDButton, context: Context) {
        context.coordinator.action = action
    }

    final class Coordinator: NSObject {
        var action: () -> Void
        init(action: @escaping () -> Void) {
            self.action = action
        }

        @objc func handleTap() {
            action()
        }
    }
}

#Preview {
    SignInView(serviceLocator: .preview)
        .preferredColorScheme(.dark)
}
