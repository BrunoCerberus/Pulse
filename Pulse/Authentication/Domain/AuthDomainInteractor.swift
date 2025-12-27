import Combine
import Foundation
import UIKit

final class AuthDomainInteractor: CombineInteractor {
    typealias DomainState = AuthDomainState
    typealias DomainAction = AuthDomainAction

    private let authService: AuthService
    private let stateSubject = CurrentValueSubject<AuthDomainState, Never>(.initial)
    private var cancellables = Set<AnyCancellable>()

    var statePublisher: AnyPublisher<AuthDomainState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var currentState: AuthDomainState {
        stateSubject.value
    }

    init(serviceLocator: ServiceLocator) {
        do {
            authService = try serviceLocator.retrieve(AuthService.self)
        } catch {
            Logger.shared.service("Failed to retrieve AuthService: \(error)", level: .warning)
            authService = LiveAuthService()
        }
    }

    func dispatch(action: AuthDomainAction) {
        switch action {
        case let .signInWithGoogle(viewController):
            signInWithGoogle(presenting: viewController)
        case .signInWithApple:
            signInWithApple()
        case .signOut:
            signOut()
        case .clearError:
            updateState { state in
                state.error = nil
            }
        }
    }

    private func signInWithGoogle(presenting viewController: UIViewController) {
        updateState { state in
            state.isLoading = true
            state.error = nil
        }

        authService.signInWithGoogle(presenting: viewController)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.updateState { state in
                        state.isLoading = false
                        if case AuthError.signInCancelled = error {
                            // Don't show error for user cancellation
                        } else {
                            state.error = error.localizedDescription
                        }
                    }
                }
            } receiveValue: { [weak self] user in
                self?.updateState { state in
                    state.isLoading = false
                    state.user = user
                }
            }
            .store(in: &cancellables)
    }

    private func signInWithApple() {
        updateState { state in
            state.isLoading = true
            state.error = nil
        }

        authService.signInWithApple()
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.updateState { state in
                        state.isLoading = false
                        if case AuthError.signInCancelled = error {
                            // Don't show error for user cancellation
                        } else {
                            state.error = error.localizedDescription
                        }
                    }
                }
            } receiveValue: { [weak self] user in
                self?.updateState { state in
                    state.isLoading = false
                    state.user = user
                }
            }
            .store(in: &cancellables)
    }

    private func signOut() {
        updateState { state in
            state.isLoading = true
        }

        authService.signOut()
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.updateState { state in
                        state.isLoading = false
                        state.error = error.localizedDescription
                    }
                }
            } receiveValue: { [weak self] in
                self?.updateState { state in
                    state.isLoading = false
                    state.user = nil
                }
            }
            .store(in: &cancellables)
    }

    private func updateState(_ transform: (inout AuthDomainState) -> Void) {
        var state = stateSubject.value
        transform(&state)
        stateSubject.send(state)
    }
}
