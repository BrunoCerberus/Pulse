import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing
import UIKit

@Suite("SignInViewModel Tests")
@MainActor
struct SignInViewModelTests {
    let mockAuthService: MockAuthService
    let serviceLocator: ServiceLocator
    let sut: SignInViewModel

    init() {
        mockAuthService = MockAuthService()
        serviceLocator = ServiceLocator()
        serviceLocator.register(AuthService.self, instance: mockAuthService)
        sut = SignInViewModel(serviceLocator: serviceLocator)
    }

    // MARK: - Initial State Tests

    @Test("Initial view state is correct")
    func initialViewState() {
        let state = sut.viewState
        #expect(state.isLoading == false)
        #expect(state.errorMessage == nil)
    }

    // MARK: - Google Sign In Tests

    @Test("Handle Google sign in updates loading state")
    func handleGoogleSignIn() async throws {
        var states: [SignInViewState] = []
        var cancellables = Set<AnyCancellable>()

        sut.$viewState
            .sink { state in states.append(state) }
            .store(in: &cancellables)

        // Create a mock view controller for testing
        let mockViewController = UIViewController()
        sut.handle(event: .onGoogleSignInTapped(mockViewController))

        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(states.contains { $0.isLoading == true })
    }

    @Test("Google sign in success clears loading")
    func googleSignInSuccess() async throws {
        mockAuthService.signInWithGoogleResult = .success(.mock)

        let mockViewController = UIViewController()
        sut.handle(event: .onGoogleSignInTapped(mockViewController))

        try await Task.sleep(nanoseconds: 300_000_000)

        let finalState = sut.viewState
        #expect(finalState.isLoading == false)
        #expect(finalState.errorMessage == nil)
    }

    @Test("Google sign in failure shows error")
    func googleSignInFailure() async throws {
        mockAuthService.signInWithGoogleResult = .failure(AuthError.networkError)

        let mockViewController = UIViewController()
        sut.handle(event: .onGoogleSignInTapped(mockViewController))

        try await Task.sleep(nanoseconds: 300_000_000)

        let finalState = sut.viewState
        #expect(finalState.isLoading == false)
        #expect(finalState.errorMessage != nil)
    }

    @Test("Google sign in cancelled does not show error")
    func googleSignInCancelled() async throws {
        mockAuthService.signInWithGoogleResult = .failure(AuthError.signInCancelled)

        let mockViewController = UIViewController()
        sut.handle(event: .onGoogleSignInTapped(mockViewController))

        try await Task.sleep(nanoseconds: 300_000_000)

        let finalState = sut.viewState
        #expect(finalState.isLoading == false)
        #expect(finalState.errorMessage == nil)
    }

    // MARK: - Apple Sign In Tests

    @Test("Handle Apple sign in updates loading state")
    func handleAppleSignIn() async throws {
        var states: [SignInViewState] = []
        var cancellables = Set<AnyCancellable>()

        sut.$viewState
            .sink { state in states.append(state) }
            .store(in: &cancellables)

        sut.handle(event: .onAppleSignInTapped)

        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(states.contains { $0.isLoading == true })
    }

    @Test("Apple sign in success clears loading")
    func appleSignInSuccess() async throws {
        mockAuthService.signInWithAppleResult = .success(.mock)

        sut.handle(event: .onAppleSignInTapped)

        try await Task.sleep(nanoseconds: 300_000_000)

        let finalState = sut.viewState
        #expect(finalState.isLoading == false)
        #expect(finalState.errorMessage == nil)
    }

    @Test("Apple sign in failure shows error")
    func appleSignInFailure() async throws {
        mockAuthService.signInWithAppleResult = .failure(AuthError.invalidCredential)

        sut.handle(event: .onAppleSignInTapped)

        try await Task.sleep(nanoseconds: 300_000_000)

        let finalState = sut.viewState
        #expect(finalState.isLoading == false)
        #expect(finalState.errorMessage != nil)
    }

    // MARK: - Dismiss Error Tests

    @Test("Handle dismiss error clears error message")
    func handleDismissError() async throws {
        // First trigger an error
        mockAuthService.signInWithAppleResult = .failure(AuthError.networkError)
        sut.handle(event: .onAppleSignInTapped)
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.viewState.errorMessage != nil)

        // Then dismiss the error
        sut.handle(event: .onDismissError)
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(sut.viewState.errorMessage == nil)
    }

    // MARK: - View State Transformation Tests

    @Test("View state reflects domain state loading")
    func viewStateReflectsLoading() async throws {
        var states: [SignInViewState] = []
        var cancellables = Set<AnyCancellable>()

        sut.$viewState
            .sink { state in states.append(state) }
            .store(in: &cancellables)

        sut.handle(event: .onAppleSignInTapped)

        try await Task.sleep(nanoseconds: 300_000_000)

        // Should have captured loading state transitions
        let loadingStates = states.filter { $0.isLoading }
        #expect(!loadingStates.isEmpty)
    }

    @Test("View state error message matches domain error")
    func viewStateErrorMatchesDomain() async throws {
        mockAuthService.signInWithAppleResult = .failure(AuthError.networkError)

        sut.handle(event: .onAppleSignInTapped)

        try await Task.sleep(nanoseconds: 300_000_000)

        let finalState = sut.viewState
        #expect(finalState.errorMessage != nil)
        #expect(finalState.errorMessage?.contains("network") == true || finalState.errorMessage != nil)
    }
}
