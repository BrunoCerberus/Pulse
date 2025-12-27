import Combine
import Foundation
@testable import Pulse
import Testing
import UIKit

@Suite("AuthDomainInteractor Tests")
@MainActor
struct AuthDomainInteractorTests {
    let mockAuthService: MockAuthService
    let serviceLocator: ServiceLocator
    let sut: AuthDomainInteractor
    let mockViewController: UIViewController

    init() {
        mockAuthService = MockAuthService()
        serviceLocator = ServiceLocator()
        serviceLocator.register(AuthService.self, instance: mockAuthService)
        sut = AuthDomainInteractor(serviceLocator: serviceLocator)
        mockViewController = UIViewController()
    }

    // MARK: - Initial State Tests

    @Test("Initial state is correct")
    func initialState() {
        let state = sut.currentState
        #expect(state.isLoading == false)
        #expect(state.user == nil)
        #expect(state.error == nil)
    }

    // MARK: - Sign In With Google Tests

    @Test("Sign in with Google sets loading state")
    func signInWithGoogleSetsLoading() async throws {
        var states: [AuthDomainState] = []
        var cancellables = Set<AnyCancellable>()

        sut.statePublisher
            .sink { state in states.append(state) }
            .store(in: &cancellables)

        sut.dispatch(action: .signInWithGoogle(presenting: mockViewController))

        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(states.contains { $0.isLoading == true })
    }

    @Test("Sign in with Google success updates user")
    func signInWithGoogleSuccess() async throws {
        let expectedUser = AuthUser.mock
        mockAuthService.signInWithGoogleResult = .success(expectedUser)

        sut.dispatch(action: .signInWithGoogle(presenting: mockViewController))

        try await Task.sleep(nanoseconds: 300_000_000)

        let finalState = sut.currentState
        #expect(finalState.isLoading == false)
        #expect(finalState.user == expectedUser)
        #expect(finalState.error == nil)
    }

    @Test("Sign in with Google failure sets error")
    func signInWithGoogleFailure() async throws {
        let testError = AuthError.networkError
        mockAuthService.signInWithGoogleResult = .failure(testError)

        sut.dispatch(action: .signInWithGoogle(presenting: mockViewController))

        try await Task.sleep(nanoseconds: 300_000_000)

        let finalState = sut.currentState
        #expect(finalState.isLoading == false)
        #expect(finalState.user == nil)
        #expect(finalState.error != nil)
    }

    @Test("Sign in with Google cancelled does not set error")
    func signInWithGoogleCancelled() async throws {
        mockAuthService.signInWithGoogleResult = .failure(AuthError.signInCancelled)

        sut.dispatch(action: .signInWithGoogle(presenting: mockViewController))

        try await Task.sleep(nanoseconds: 300_000_000)

        let finalState = sut.currentState
        #expect(finalState.isLoading == false)
        #expect(finalState.error == nil)
    }

    // MARK: - Sign In With Apple Tests

    @Test("Sign in with Apple sets loading state")
    func signInWithAppleSetsLoading() async throws {
        var states: [AuthDomainState] = []
        var cancellables = Set<AnyCancellable>()

        sut.statePublisher
            .sink { state in states.append(state) }
            .store(in: &cancellables)

        sut.dispatch(action: .signInWithApple)

        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(states.contains { $0.isLoading == true })
    }

    @Test("Sign in with Apple success updates user")
    func signInWithAppleSuccess() async throws {
        let expectedUser = AuthUser.mock
        mockAuthService.signInWithAppleResult = .success(expectedUser)

        sut.dispatch(action: .signInWithApple)

        try await Task.sleep(nanoseconds: 300_000_000)

        let finalState = sut.currentState
        #expect(finalState.isLoading == false)
        #expect(finalState.user == expectedUser)
        #expect(finalState.error == nil)
    }

    @Test("Sign in with Apple failure sets error")
    func signInWithAppleFailure() async throws {
        let testError = AuthError.invalidCredential
        mockAuthService.signInWithAppleResult = .failure(testError)

        sut.dispatch(action: .signInWithApple)

        try await Task.sleep(nanoseconds: 300_000_000)

        let finalState = sut.currentState
        #expect(finalState.isLoading == false)
        #expect(finalState.user == nil)
        #expect(finalState.error != nil)
    }

    // MARK: - Sign Out Tests

    @Test("Sign out clears user")
    func signOutClearsUser() async throws {
        // First sign in
        mockAuthService.signInWithGoogleResult = .success(.mock)
        sut.dispatch(action: .signInWithGoogle(presenting: mockViewController))
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.currentState.user != nil)

        // Then sign out
        mockAuthService.signOutResult = .success(())
        sut.dispatch(action: .signOut)

        try await Task.sleep(nanoseconds: 300_000_000)

        let finalState = sut.currentState
        #expect(finalState.user == nil)
        #expect(finalState.error == nil)
    }

    @Test("Sign out failure sets error")
    func signOutFailure() async throws {
        mockAuthService.signOutResult = .failure(AuthError.unknown("Sign out failed"))

        sut.dispatch(action: .signOut)

        try await Task.sleep(nanoseconds: 300_000_000)

        let finalState = sut.currentState
        #expect(finalState.error != nil)
    }

    // MARK: - Clear Error Tests

    @Test("Clear error removes error from state")
    func clearErrorRemovesError() async throws {
        // First create an error state
        mockAuthService.signInWithGoogleResult = .failure(AuthError.networkError)
        sut.dispatch(action: .signInWithGoogle(presenting: mockViewController))
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.currentState.error != nil)

        // Then clear the error
        sut.dispatch(action: .clearError)

        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(sut.currentState.error == nil)
    }
}
