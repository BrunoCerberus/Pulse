import Combine
import EntropyCore
import Foundation

/// Domain interactor for Passkey Management.
final class PasskeyManagementDomainInteractor: CombineInteractor {
    typealias DomainState = PasskeyManagementDomainState
    typealias DomainAction = PasskeyManagementDomainAction

    private let authService: AuthService
    private var cancellables = Set<AnyCancellable>()
    private let stateSubject = CurrentValueSubject<DomainState, Never>(.initial)

    var statePublisher: AnyPublisher<DomainState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var currentState: DomainState {
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

    func dispatch(action: DomainAction) {
        switch action {
        case .loadPasskeys:
            loadPasskeys()
        case let .deletePasskey(username):
            deletePasskey(username: username)
        case .registerPasskey:
            registerPasskey()
        case .clearError:
            updateState { state in
                state.error = nil
            }
        }
    }

    private func loadPasskeys() {
        updateState { state in
            state.isLoading = true
            state.error = nil
        }

        authService.getAvailablePasskeys()
            .receive(on: DispatchQueue.main)
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
            } receiveValue: { [weak self] usernames in
                self?.updateState { state in
                    state.isLoading = false
                    state.passkeys = usernames
                }
            }
            .store(in: &cancellables)
    }

    private func deletePasskey(username: String) {
        updateState { state in
            state.isLoading = true
            state.error = nil
        }

        authService.deletePasskey(username: username)
            .receive(on: DispatchQueue.main)
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
            } receiveValue: { [weak self] _ in
                // Refresh the list after deletion.
                self?.loadPasskeys()
            }
            .store(in: &cancellables)
    }

    private func registerPasskey() {
        updateState { state in
            state.isLoading = true
            state.error = nil
        }

        authService.registerPasskey()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.updateState { state in
                        state.isLoading = false
                        if case AuthError.signInCancelled = error {
                            // Don't show error for user cancellation
                        } else if case AuthError.noPasskeysAvailable = error {
                            // User already has a passkey — nothing to do.
                        } else {
                            state.error = error.localizedDescription
                        }
                    }
                }
            } receiveValue: { [weak self] _ in
                // Refresh the list after successful registration.
                self?.loadPasskeys()
            }
            .store(in: &cancellables)
    }

    private func updateState(_ transform: (inout DomainState) -> Void) {
        var state = stateSubject.value
        transform(&state)
        stateSubject.send(state)
    }
}
