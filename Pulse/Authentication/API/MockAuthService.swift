import Combine
import UIKit

final class MockAuthService: AuthService {
    private let authStateSubject = CurrentValueSubject<AuthUser?, Never>(nil)

    var signInResult: Result<AuthUser, Error> = .success(AuthUser.mock)
    var signOutResult: Result<Void, Error> = .success(())

    var authStatePublisher: AnyPublisher<AuthUser?, Never> {
        authStateSubject.eraseToAnyPublisher()
    }

    var currentUser: AuthUser? {
        authStateSubject.value
    }

    func signInWithGoogle(presenting _: UIViewController) -> AnyPublisher<AuthUser, Error> {
        signInResult.publisher
            .handleEvents(receiveOutput: { [weak self] user in
                self?.authStateSubject.send(user)
            })
            .eraseToAnyPublisher()
    }

    func signInWithApple() -> AnyPublisher<AuthUser, Error> {
        signInResult.publisher
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
