import Combine
import EntropyCore
import Foundation
import UIKit

/// Domain interactor for the Authentication feature.
///
/// Manages business logic and state for user authentication, including:
/// - Sign in with Google (Firebase Auth)
/// - Sign in with Apple (Firebase Auth)
/// - Sign out
/// - Error handling with user cancellation detection
///
/// ## Data Flow
/// 1. Views dispatch `AuthDomainAction` via `dispatch(action:)`
/// 2. Interactor processes actions and updates `AuthDomainState`
/// 3. State changes are published via `statePublisher`
///
/// ## Dependencies
/// - `AuthService`: Firebase Auth implementation
final class AuthDomainInteractor: CombineInteractor {
    typealias DomainState = AuthDomainState
    typealias DomainAction = AuthDomainAction

    private let authService: AuthService
    private let analyticsService: AnalyticsService?
    private let stateSubject = CurrentValueSubject<DomainState, Never>(.initial)
    private var cancellables = Set<AnyCancellable>()

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

        analyticsService = try? serviceLocator.retrieve(AnalyticsService.self)
    }

    func dispatch(action: DomainAction) {
        switch action {
        case let .signInWithGoogle(viewController):
            signInWithGoogle(presenting: viewController)
        case .signInWithApple:
            signInWithApple()
        case .signInWithPasskey:
            signInWithPasskey()
        case .registerPasskey:
            registerPasskey()
        case .loadPasskeys:
            loadPasskeys()
        case let .deletePasskey(username):
            deletePasskey(username: username)
        case .signInAnonymously:
            signInAnonymously()
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
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    if case AuthError.signInCancelled = error {
                        // Don't track or show error for user cancellation
                    } else {
                        self?.analyticsService?.logEvent(.signIn(provider: "google", success: false))
                        self?.analyticsService?.recordError(error)
                    }
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
                self?.analyticsService?.logEvent(.signIn(provider: "google", success: true))
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
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    if case AuthError.signInCancelled = error {
                        // Don't track or show error for user cancellation
                    } else {
                        self?.analyticsService?.logEvent(.signIn(provider: "apple", success: false))
                        self?.analyticsService?.recordError(error)
                    }
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
                self?.analyticsService?.logEvent(.signIn(provider: "apple", success: true))
                self?.updateState { state in
                    state.isLoading = false
                    state.user = user
                }
            }
            .store(in: &cancellables)
    }

    private func signInAnonymously() {
        updateState { state in
            state.isLoading = true
            state.error = nil
        }

        authService.signInAnonymously()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    // Reviewer-only path: log to analytics/Crashlytics but keep
                    // the UI silent. A real user who stumbles on the 5-tap
                    // gesture should never see a raw Firebase error string; a
                    // reviewer blocked by a backend issue will report it
                    // out-of-band rather than via the alert sheet.
                    //
                    // The throttle-rejection case is special-cased: it's a
                    // local UX guard, not a sign-in failure worth shipping to
                    // Crashlytics or counting as a failed `signIn` event. The
                    // whole point of M3 + M9 was to keep reviewer-pass noise
                    // OUT of analytics; reporting throttle hits would defeat
                    // both fixes.
                    if case AuthError.anonymousSignInThrottled = error {
                        self?.updateState { state in
                            state.isLoading = false
                        }
                        return
                    }
                    self?.analyticsService?.logEvent(.signIn(provider: "anonymous", success: false))
                    self?.analyticsService?.recordError(error)
                    self?.updateState { state in
                        state.isLoading = false
                    }
                }
            } receiveValue: { [weak self] user in
                self?.analyticsService?.logEvent(.signIn(provider: "anonymous", success: true))
                self?.updateState { state in
                    state.isLoading = false
                    state.user = user
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Passkey Methods

    private func signInWithPasskey() {
        updateState { state in
            state.isLoading = true
            state.error = nil
        }

        authService.signInWithPasskey()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    if case AuthError.signInCancelled = error {
                        // Don't track or show error for user cancellation
                    } else if case AuthError.noPasskeysAvailable = error {
                        // No passkeys — surface as info so the UI can offer
                        // registration instead of a raw error.
                        self?.updateState { state in
                            state.isLoading = false
                            state.error = error.localizedDescription
                        }
                    } else {
                        self?.analyticsService?.logEvent(.signIn(provider: "passkey", success: false))
                        self?.analyticsService?.recordError(error)
                    }
                    self?.updateState { state in
                        state.isLoading = false
                        if case AuthError.signInCancelled = error {
                            // Don't show error for user cancellation
                        } else if case AuthError.noPasskeysAvailable = error {
                            // Not shown to user — handled by UI offering registration
                        } else {
                            state.error = error.localizedDescription
                        }
                    }
                }
            } receiveValue: { [weak self] user in
                self?.analyticsService?.logEvent(.signIn(provider: "passkey", success: true))
                self?.updateState { state in
                    state.isLoading = false
                    state.user = user
                    state.hasPasskey = true
                }
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
                    if case AuthError.signInCancelled = error {
                        // Don't track or show error for user cancellation
                    } else {
                        self?.analyticsService?.recordError(error)
                    }
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
                self?.analyticsService?.logEvent(.passkeyRegistered(method: "explicit"))
                self?.updateState { state in
                    state.isLoading = false
                    state.user = user
                    state.hasPasskey = true
                }
            }
            .store(in: &cancellables)
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
                    if case AuthError.signInCancelled = error {
                        // Don't track or show error for user cancellation
                    } else {
                        self?.analyticsService?.recordError(error)
                    }
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
                    // Store passkey count as a hint for UI display.
                    // The interactor doesn't carry the full list — that's
                    // managed at the view level to keep Domain UI-agnostic.
                    state.hasPasskey = !usernames.isEmpty
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
                    if case AuthError.signInCancelled = error {
                        // Don't track or show error for user cancellation
                    } else {
                        self?.analyticsService?.recordError(error)
                    }
                    self?.updateState { state in
                        state.isLoading = false
                        if case AuthError.signInCancelled = error {
                            // Don't show error for user cancellation
                        } else {
                            state.error = error.localizedDescription
                        }
                    }
                }
            } receiveValue: { [weak self] in
                self?.analyticsService?.logEvent(.passkeyDeleted(username: username))
                // Remove the passkey flag from UserDefaults so subsequent
                // auth state reads reflect the new reality.
                UserDefaults.standard.removeObject(forKey: AuthUserKeys.hasPasskey)
                self?.updateState { state in
                    state.isLoading = false
                    state.hasPasskey = false
                }
            }
            .store(in: &cancellables)
    }

    private func signOut() {
        updateState { state in
            state.isLoading = true
        }

        authService.signOut()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.updateState { state in
                        state.isLoading = false
                        state.error = error.localizedDescription
                    }
                }
            } receiveValue: { [weak self] in
                self?.analyticsService?.logEvent(.signOut)
                self?.updateState { state in
                    state.isLoading = false
                    state.user = nil
                }
            }
            .store(in: &cancellables)
    }

    private func updateState(_ transform: (inout DomainState) -> Void) {
        var state = stateSubject.value
        transform(&state)
        stateSubject.send(state)
    }
}
