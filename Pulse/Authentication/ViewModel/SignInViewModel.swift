import Combine
import EntropyCore
import Foundation
import UIKit

/// ViewModel for the Sign In screen.
///
/// Implements `CombineViewModel` to handle authentication via Google, Apple, and Passkey Sign-In.
/// Provides loading state and error handling for auth operations.
///
/// ## Features
/// - Google Sign-In via Firebase Auth
/// - Apple Sign-In via Firebase Auth (supports Passkeys on iOS 16+)
/// - Explicit Passkey sign-in and registration via WebAuthn
/// - Error display with dismiss action
@MainActor
final class SignInViewModel: CombineViewModel, ObservableObject {
    typealias ViewState = SignInViewState
    typealias ViewEvent = SignInViewEvent

    @Published private(set) var viewState: SignInViewState = .initial

    private let interactor: AuthDomainInteractor

    init(serviceLocator: ServiceLocator) {
        interactor = AuthDomainInteractor(serviceLocator: serviceLocator)
        setupBindings()
    }

    func handle(event: SignInViewEvent) {
        switch event {
        case let .onGoogleSignInTapped(viewController):
            interactor.dispatch(action: .signInWithGoogle(presenting: viewController))
        case .onAppleSignInTapped:
            interactor.dispatch(action: .signInWithApple)
        case .onPasskeySignInTapped:
            interactor.dispatch(action: .signInWithPasskey)
        case .registerPasskeyTapped:
            interactor.dispatch(action: .registerPasskey)
        case .onReviewerSignInTriggered:
            interactor.dispatch(action: .signInAnonymously)
        case .onDismissError:
            interactor.dispatch(action: .clearError)
        }
    }

    private func setupBindings() {
        interactor.statePublisher
            .map { state in
                SignInViewState(
                    isLoading: state.isLoading,
                    errorMessage: state.error
                )
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$viewState)
    }
}

struct SignInViewState: Equatable {
    var isLoading: Bool
    var errorMessage: String?

    static var initial: SignInViewState {
        SignInViewState(isLoading: false, errorMessage: nil)
    }
}

enum SignInViewEvent {
    case onGoogleSignInTapped(UIViewController)
    case onAppleSignInTapped
    case onPasskeySignInTapped
    case registerPasskeyTapped
    /// Hidden reviewer entry point. Fired by the 5-tap gesture on the logo
    /// and dispatched as an anonymous Firebase sign-in. See `SignInView` and
    /// the App Review Information section in App Store Connect.
    case onReviewerSignInTriggered
    case onDismissError
}
