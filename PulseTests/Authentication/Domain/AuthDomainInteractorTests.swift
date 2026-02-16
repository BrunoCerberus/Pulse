import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing
import UIKit

@Suite("AuthDomainInteractor Tests")
@MainActor
struct AuthDomainInteractorTests {
    let mockAuthService: MockAuthService
    let mockAnalyticsService: MockAnalyticsService
    let serviceLocator: ServiceLocator
    let sut: AuthDomainInteractor
    let mockViewController: UIViewController

    init() {
        mockAuthService = MockAuthService()
        mockAnalyticsService = MockAnalyticsService()
        serviceLocator = ServiceLocator()
        serviceLocator.register(AuthService.self, instance: mockAuthService)
        serviceLocator.register(AnalyticsService.self, instance: mockAnalyticsService)
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

    // MARK: - Sign In Tests (Consolidated for both providers)

    @Test("Sign in sets loading state and handles success correctly")
    func signInSuccessFlow() async throws {
        let expectedUser = AuthUser.mock

        // Test Google Sign In
        mockAuthService.signInWithGoogleResult = .success(expectedUser)
        var states: [AuthDomainState] = []
        var cancellables = Set<AnyCancellable>()

        sut.statePublisher
            .sink { state in states.append(state) }
            .store(in: &cancellables)

        sut.dispatch(action: .signInWithGoogle(presenting: mockViewController))
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(states.contains { $0.isLoading == true })
        #expect(sut.currentState.isLoading == false)
        #expect(sut.currentState.user == expectedUser)
        #expect(sut.currentState.error == nil)

        // Reset for Apple Sign In test
        sut.dispatch(action: .signOut)
        try await Task.sleep(nanoseconds: 300_000_000)

        mockAuthService.signInWithAppleResult = .success(expectedUser)
        sut.dispatch(action: .signInWithApple)
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.currentState.user == expectedUser)
        #expect(sut.currentState.error == nil)
    }

    @Test("Sign in failure sets error state")
    func signInFailureFlow() async throws {
        // Test Google Sign In failure
        mockAuthService.signInWithGoogleResult = .failure(AuthError.networkError)
        sut.dispatch(action: .signInWithGoogle(presenting: mockViewController))
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.currentState.isLoading == false)
        #expect(sut.currentState.user == nil)
        #expect(sut.currentState.error != nil)

        // Clear error and test Apple Sign In failure
        sut.dispatch(action: .clearError)
        try await Task.sleep(nanoseconds: 100_000_000)

        mockAuthService.signInWithAppleResult = .failure(AuthError.invalidCredential)
        sut.dispatch(action: .signInWithApple)
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.currentState.isLoading == false)
        #expect(sut.currentState.user == nil)
        #expect(sut.currentState.error != nil)
    }

    @Test("Sign in cancelled does not set error")
    func signInCancelledDoesNotSetError() async throws {
        mockAuthService.signInWithGoogleResult = .failure(AuthError.signInCancelled)

        sut.dispatch(action: .signInWithGoogle(presenting: mockViewController))
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.currentState.isLoading == false)
        #expect(sut.currentState.error == nil)
    }

    // MARK: - Sign Out Tests (Consolidated)

    @Test("Sign out clears user and handles errors")
    func signOutFlow() async throws {
        // First sign in
        mockAuthService.signInWithGoogleResult = .success(.mock)
        sut.dispatch(action: .signInWithGoogle(presenting: mockViewController))
        try await Task.sleep(nanoseconds: 300_000_000)
        #expect(sut.currentState.user != nil)

        // Test successful sign out
        mockAuthService.signOutResult = .success(())
        sut.dispatch(action: .signOut)
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.currentState.user == nil)
        #expect(sut.currentState.error == nil)

        // Test sign out failure
        mockAuthService.signOutResult = .failure(AuthError.unknown("Sign out failed"))
        sut.dispatch(action: .signOut)
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.currentState.error != nil)
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

    // MARK: - Analytics Tests

    @Test("Logs sign_in on successful Google sign in")
    func logsSignInOnGoogleSuccess() async throws {
        mockAuthService.signInWithGoogleResult = .success(.mock)
        sut.dispatch(action: .signInWithGoogle(presenting: mockViewController))
        try await Task.sleep(nanoseconds: 300_000_000)

        let signInEvents = mockAnalyticsService.loggedEvents.filter { $0.name == "sign_in" }
        #expect(signInEvents.count == 1)
        #expect(signInEvents.first?.parameters?["provider"] as? String == "google")
        #expect(signInEvents.first?.parameters?["success"] as? Bool == true)
    }

    @Test("Logs sign_in failure on Google sign in error")
    func logsSignInFailureOnGoogleError() async throws {
        mockAuthService.signInWithGoogleResult = .failure(AuthError.networkError)
        sut.dispatch(action: .signInWithGoogle(presenting: mockViewController))
        try await Task.sleep(nanoseconds: 300_000_000)

        let signInEvents = mockAnalyticsService.loggedEvents.filter { $0.name == "sign_in" }
        #expect(signInEvents.count == 1)
        #expect(signInEvents.first?.parameters?["success"] as? Bool == false)
        #expect(mockAnalyticsService.recordedErrors.count == 1)
    }

    @Test("Does not log analytics on cancelled sign in")
    func doesNotLogOnCancelledSignIn() async throws {
        mockAuthService.signInWithGoogleResult = .failure(AuthError.signInCancelled)
        sut.dispatch(action: .signInWithGoogle(presenting: mockViewController))
        try await Task.sleep(nanoseconds: 300_000_000)

        let signInEvents = mockAnalyticsService.loggedEvents.filter { $0.name == "sign_in" }
        #expect(signInEvents.isEmpty)
        #expect(mockAnalyticsService.recordedErrors.isEmpty)
    }

    @Test("Logs sign_in on successful Apple sign in")
    func logsSignInOnAppleSuccess() async throws {
        mockAuthService.signInWithAppleResult = .success(.mock)
        sut.dispatch(action: .signInWithApple)
        try await Task.sleep(nanoseconds: 300_000_000)

        let signInEvents = mockAnalyticsService.loggedEvents.filter { $0.name == "sign_in" }
        #expect(signInEvents.count == 1)
        #expect(signInEvents.first?.parameters?["provider"] as? String == "apple")
        #expect(signInEvents.first?.parameters?["success"] as? Bool == true)
    }

    @Test("Logs sign_out on successful sign out")
    func logsSignOutOnSuccess() async throws {
        mockAuthService.signInWithGoogleResult = .success(.mock)
        sut.dispatch(action: .signInWithGoogle(presenting: mockViewController))
        try await Task.sleep(nanoseconds: 300_000_000)

        mockAuthService.signOutResult = .success(())
        sut.dispatch(action: .signOut)
        try await Task.sleep(nanoseconds: 300_000_000)

        let signOutEvents = mockAnalyticsService.loggedEvents.filter { $0.name == "sign_out" }
        #expect(signOutEvents.count == 1)
    }
}
