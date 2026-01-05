import Combine
import UIKit

final class MockAuthService: AuthService {
    private let authStateSubject: CurrentValueSubject<AuthUser?, Never>

    var signInWithGoogleResult: Result<AuthUser, Error> = .success(AuthUser.mock)

    /// Property to set initial auth state for testing.
    /// Setting this updates the auth state subject immediately.
    var mockCurrentUser: AuthUser? {
        get { authStateSubject.value }
        set { authStateSubject.send(newValue) }
    }

    /// Initialize MockAuthService.
    /// When running UI tests (UI_TESTING=1), starts in authenticated state.
    init() {
        // Auto-authenticate for UI tests so the tab bar appears immediately
        let isUITesting = ProcessInfo.processInfo.environment["UI_TESTING"] == "1"
        authStateSubject = CurrentValueSubject(isUITesting ? AuthUser.mock : nil)
    }

    var signInWithAppleResult: Result<AuthUser, Error> = .success(AuthUser.mock)
    var signOutResult: Result<Void, Error> = .success(())

    var authStatePublisher: AnyPublisher<AuthUser?, Never> {
        authStateSubject.eraseToAnyPublisher()
    }

    var currentUser: AuthUser? {
        authStateSubject.value
    }

    func signInWithGoogle(presenting _: UIViewController) -> AnyPublisher<AuthUser, Error> {
        signInWithGoogleResult.publisher
            .handleEvents(receiveOutput: { [weak self] user in
                self?.authStateSubject.send(user)
            })
            .eraseToAnyPublisher()
    }

    func signInWithApple() -> AnyPublisher<AuthUser, Error> {
        signInWithAppleResult.publisher
            .handleEvents(receiveOutput: { [weak self] user in
                self?.authStateSubject.send(user)
            })
            .eraseToAnyPublisher()
    }

    func signOut() -> AnyPublisher<Void, Error> {
        signOutResult.publisher
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.authStateSubject.send(nil)
            })
            .eraseToAnyPublisher()
    }

    // For testing: simulate signed-in state
    func simulateSignedIn(_ user: AuthUser) {
        authStateSubject.send(user)
    }

    func simulateSignedOut() {
        authStateSubject.send(nil)
    }
}

extension AuthUser {
    static var mock: AuthUser {
        AuthUser(
            uid: "mock-uid-123",
            email: "test@example.com",
            displayName: "Test User",
            photoURL: URL(string: "https://example.com/avatar.png"),
            provider: .google
        )
    }
}
