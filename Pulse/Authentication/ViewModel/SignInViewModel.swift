import Combine
import EntropyCore
import Foundation
import UIKit

/// ViewModel for the Sign In screen.
///
/// Implements `CombineViewModel` to handle authentication via Google and Apple Sign-In.
/// Provides loading state and error handling for auth operations.
///
/// ## Features
/// - Google Sign-In via Firebase Auth
/// - Apple Sign-In via Firebase Auth
/// - Error display with dismiss action
@MainActor
final class SignInViewModel: CombineViewModel, ObservableObject {
    typealias ViewState = SignInViewState
    typealias ViewEvent = SignInViewEvent

    @Published private(set) var viewState: SignInViewState = .initial

    private let interactor: AuthDomainInteractor
    private var cancellables = Set<AnyCancellable>()

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
    case onDismissError
}
