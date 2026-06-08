import Combine
import Foundation

/// Global authentication state manager.
/// Observable class that publishes authentication state changes.
@MainActor
final class AuthenticationManager: ObservableObject {
    /// Singleton instance for app-wide auth state observation
    static let shared = AuthenticationManager()

    /// Current authentication state
    @Published private(set) var authState: AuthState = .loading

    /// Current authenticated user (if any)
    @Published private(set) var currentUser: AuthUser?

    /// Publisher for auth state that can be accessed from any context
    var authStatePublisher: AnyPublisher<AuthState, Never> {
        $authState.eraseToAnyPublisher()
    }

    private var authService: AuthService?
    private var cancellables = Set<AnyCancellable>()

    /// Cleanup invoked when the user transitions from authenticated to
    /// unauthenticated. Covers server-driven sign-outs (token revoked, account
    /// disabled or deleted on another device) that never go through the Settings
    /// sign-out/delete flow and would otherwise leave local data on the device.
    /// Wired in `PulseSceneDelegate`; single-flight is enforced downstream by
    /// `SettingsViewModel.clearAllUserData`, so firing it alongside the Settings
    /// flow is safe.
    private var sessionCleanup: (@MainActor () async -> Void)?

    /// Registers the local-data wipe to run on sign-out transitions. See
    /// `sessionCleanup`.
    func configureSessionCleanup(_ cleanup: @escaping @MainActor () async -> Void) {
        sessionCleanup = cleanup
    }

    enum AuthState: Equatable {
        case loading
        case authenticated(AuthUser)
        case unauthenticated

        static func == (lhs: AuthState, rhs: AuthState) -> Bool {
            switch (lhs, rhs) {
            case (.loading, .loading): return true
            case (.unauthenticated, .unauthenticated): return true
            case let (.authenticated(lhsUser), .authenticated(rhsUser)): return lhsUser == rhsUser
            default: return false
            }
        }
    }

    private init() {}

    /// Configure with auth service (called during app setup)
    func configure(with authService: AuthService) {
        self.authService = authService

        // Immediately set current state from auth service (synchronous)
        // This ensures the UI has correct state before any async pipeline fires
        if let user = authService.currentUser {
            authState = .authenticated(user)
            currentUser = user
        } else {
            authState = .unauthenticated
            currentUser = nil
        }

        // Subscribe to future auth state changes
        authService.authStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                guard let self else { return }
                let wasAuthenticated = self.isAuthenticated
                if let user {
                    self.authState = .authenticated(user)
                    self.currentUser = user
                } else {
                    self.authState = .unauthenticated
                    self.currentUser = nil
                    // Only a genuine authenticated → unauthenticated transition
                    // triggers cleanup. A cold-launch `loading → unauthenticated`
                    // or a redundant unauthenticated emission must NOT wipe — that
                    // would erase a returning (or still signed-in) user's data.
                    if wasAuthenticated {
                        self.runSessionCleanup()
                    }
                }
            }
            .store(in: &cancellables)
    }

    /// Fires the registered `sessionCleanup` (if any) on the main actor.
    private func runSessionCleanup() {
        guard let sessionCleanup else { return }
        Task { @MainActor in
            await sessionCleanup()
        }
    }

    /// Check if user is authenticated
    var isAuthenticated: Bool {
        if case .authenticated = authState {
            return true
        }
        return false
    }

    #if DEBUG
        /// For testing: directly set authenticated state (bypasses async Combine pipeline)
        func setAuthenticatedForTesting(_ user: AuthUser) {
            authState = .authenticated(user)
            currentUser = user
        }

        /// For testing: directly set unauthenticated state
        func setUnauthenticatedForTesting() {
            authState = .unauthenticated
            currentUser = nil
        }

        /// For testing: reset singleton to clean state between tests
        /// Clears auth service, cancellables, and resets to loading state
        func resetForTesting() {
            authService = nil
            cancellables.removeAll()
            authState = .loading
            currentUser = nil
            sessionCleanup = nil
        }
    #endif
}
