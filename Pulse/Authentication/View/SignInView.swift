import AuthenticationServices
import SwiftUI

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
        .alert("Sign In Error", isPresented: $showError) {
            Button("OK") {
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
                    .font(.system(size: 48))
                    .foregroundStyle(.white)
            }
            .glowEffect(color: Color.Accent.primary, radius: 20)

            VStack(spacing: Spacing.xs) {
                Text("Pulse")
                    .font(Typography.displayLarge)
                    .foregroundStyle(.white)

                Text("Your personalized news experience")
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
                        .font(.system(size: 20))

                    Text("Sign in with Apple")
                        .font(Typography.labelLarge)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.white)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
            }
            .buttonStyle(.plain)

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

                    Text("Sign in with Google")
                        .font(Typography.labelLarge)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.white)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
            }
            .buttonStyle(.plain)
        }
    }

    private var googleLogo: some View {
        // Google "G" logo using SF Symbol as fallback
        // In production, add a google_logo image to Assets
        Image(systemName: "g.circle.fill")
            .font(.system(size: 20))
            .foregroundStyle(
                .linearGradient(
                    colors: [.red, .yellow, .green, .blue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    private var termsSection: some View {
        Text("By signing in, you agree to our Terms of Service and Privacy Policy")
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

                Text("Signing in...")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(.white)
            }
            .padding(Spacing.xl)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        }
    }
}

#Preview {
    SignInView(serviceLocator: .preview)
}
