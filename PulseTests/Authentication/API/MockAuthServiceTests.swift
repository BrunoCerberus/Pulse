import Combine
import Foundation
@testable import Pulse
import Testing
import UIKit

@Suite("MockAuthService Tests")
struct MockAuthServiceTests {
    var sut: MockAuthService

    init() {
        sut = MockAuthService()
    }

    @Test("Initial state is not authenticated")
    func initialStateNotAuthenticated() {
        #expect(sut.currentUser == nil)
    }

    @Test("Auth state publisher emits initial state")
    func authStatePublisherEmitsInitial() {
        var receivedStates: [AuthUser?] = []
        let cancellable = sut.authStatePublisher
            .sink { state in
                receivedStates.append(state)
            }

        #expect(!receivedStates.isEmpty)

        cancellable.cancel()
    }

    @Test("SignIn with Google success updates auth state")
    func signInWithGoogleSuccess() async throws {
        let mockUser = AuthUser.mock
        sut.signInWithGoogleResult = .success(mockUser)

        let viewController = UIViewController()

        let publisher = sut.signInWithGoogle(presenting: viewController)
        var receivedUser: AuthUser?
        let cancellable = publisher
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { user in
                    receivedUser = user
                }
            )

        try await waitForStateUpdate()
        cancellable.cancel()

        #expect(receivedUser != nil)
        #expect(sut.currentUser?.uid == mockUser.uid)
    }

    @Test("SignIn with Google failure does not update auth state")
    func signInWithGoogleFailure() async throws {
        let mockError = AuthError.invalidCredential
        sut.signInWithGoogleResult = .failure(mockError)

        let viewController = UIViewController()

        let publisher = sut.signInWithGoogle(presenting: viewController)
        var receivedError: Error?
        let cancellable = publisher
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        receivedError = error
                    }
                },
                receiveValue: { _ in }
            )

        try await waitForStateUpdate()
        cancellable.cancel()

        #expect(receivedError != nil)
    }

    @Test("SignIn with Apple success updates auth state")
    func signInWithAppleSuccess() async throws {
        let mockUser = AuthUser.mock
        sut.signInWithAppleResult = .success(mockUser)

        let publisher = sut.signInWithApple()
        var receivedUser: AuthUser?
        let cancellable = publisher
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { user in
                    receivedUser = user
                }
            )

        try await waitForStateUpdate()
        cancellable.cancel()

        #expect(receivedUser != nil)
        #expect(sut.currentUser?.uid == mockUser.uid)
    }

    @Test("SignIn with Apple failure does not update auth state")
    func signInWithAppleFailure() async throws {
        let mockError = AuthError.invalidCredential
        sut.signInWithAppleResult = .failure(mockError)

        let publisher = sut.signInWithApple()
        var receivedError: Error?
        let cancellable = publisher
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        receivedError = error
                    }
                },
                receiveValue: { _ in }
            )

        try await waitForStateUpdate()
        cancellable.cancel()

        #expect(receivedError != nil)
    }

    @Test("Sign out clears auth state")
    func signOutClearsAuthState() async throws {
        sut.simulateSignedIn(.mock)

        let publisher = sut.signOut()
        var receivedCompletion: Subscribers.Completion<Error>?
        let cancellable = publisher
            .sink(
                receiveCompletion: { completion in
                    receivedCompletion = completion
                },
                receiveValue: { _ in }
            )

        try await waitForStateUpdate()
        cancellable.cancel()

        #expect(sut.currentUser == nil)
    }

    @Test("Sign out failure")
    func signOutFailure() async throws {
        sut.simulateSignedIn(.mock)
        let mockError = AuthError.unknown("Sign out failed")
        sut.signOutResult = .failure(mockError)

        let publisher = sut.signOut()
        var receivedError: Error?
        let cancellable = publisher
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        receivedError = error
                    }
                },
                receiveValue: { _ in }
            )

        try await waitForStateUpdate()
        cancellable.cancel()

        #expect(receivedError != nil)
    }

    @Test("Simulate signed in updates auth state")
    func simulateSignedInUpdatesState() {
        let mockUser = AuthUser.mock
        sut.simulateSignedIn(mockUser)

        #expect(sut.currentUser?.uid == mockUser.uid)
    }

    @Test("Simulate signed out clears auth state")
    func simulateSignedOutClearsState() {
        sut.simulateSignedIn(.mock)
        sut.simulateSignedOut()

        #expect(sut.currentUser == nil)
    }

    @Test("Mock current user property updates auth state")
    func mockCurrentUserUpdatesState() {
        let mockUser = AuthUser.mock
        sut.mockCurrentUser = mockUser

        #expect(sut.currentUser?.uid == mockUser.uid)
    }
}
