import AuthenticationServices
import EntropyCore
import SwiftUI

// MARK: - Constants

private enum Constants {
    static let appName = String(localized: "app.name")
    static let tagline = String(localized: "auth.tagline")
    static let signInApple = String(localized: "auth.sign_in_apple")
    static let signInGoogle = String(localized: "auth.sign_in_google")
    static let terms = String(localized: "auth.terms")
    static let signingIn = String(localized: "auth.signing_in")
    static let error = String(localized: "common.error")
    static let okButton = String(localized: "common.ok")
}

// MARK: - SignInView

struct SignInView: View {
    @StateObject private var viewModel: SignInViewModel
    @State private var showError = false

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
            Text(viewModel.viewState.errorMessage ?? "An unknown error occurred")
        }
        .onChange(of: viewModel.viewState.errorMessage) { _, newValue in
            showError = newValue != nil
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
            .glowEffect(color: Color.Accent.primary, radius: 20)
            .accessibilityHidden(true)

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
            // Sign in with Apple
            Button {
                HapticManager.shared.buttonPress()
                viewModel.handle(event: .onAppleSignInTapped)
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "apple.logo")
                        .font(.headline)

                    Text(Constants.signInApple)
                        .font(Typography.labelLarge)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.white)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Constants.signInApple)
            .accessibilityHint("Double tap to sign in with your Apple ID")

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
            .accessibilityHint("Double tap to sign in with your Google account")
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
                    endPoint: .bottomTrailing
                )
            )
    }

    private var termsSection: some View {
        Text(Constants.terms)
            .font(Typography.captionMedium)
            .foregroundStyle(.white.opacity(0.5))
            .multilineTextAlignment(.center)
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
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Constants.signingIn)
        }
    }
}

#Preview {
    SignInView(serviceLocator: .preview)
        .preferredColorScheme(.dark)
}
