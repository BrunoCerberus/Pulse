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
    nonisolated var authStatePublisher: AnyPublisher<AuthState, Never> {
        MainActor.assumeIsolated {
            $authState.eraseToAnyPublisher()
        }
    }

    private var authService: AuthService?
    private var cancellables = Set<AnyCancellable>()

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
                if let user {
                    self?.authState = .authenticated(user)
                    self?.currentUser = user
                } else {
                    self?.authState = .unauthenticated
                    self?.currentUser = nil
                }
            }
            .store(in: &cancellables)
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
    #endif
}
