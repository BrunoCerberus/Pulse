import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("SignInViewModel Passkey Tests")
@MainActor
struct SignInViewModelPasskeyTests {
    let mockAuthService: MockAuthService
    let serviceLocator: ServiceLocator
    let sut: SignInViewModel

    init() {
        mockAuthService = MockAuthService()
        serviceLocator = ServiceLocator()
        serviceLocator.register(AuthService.self, instance: mockAuthService)
        sut = SignInViewModel(serviceLocator: serviceLocator)
    }

    // MARK: - Event Dispatch Tests

    @Test("Passkey sign-in event dispatches correct domain action")
    func passkeySignInDispatchesAction() async throws {
        mockAuthService.signInWithPasskeyResult = .success(AuthUser.mock)

        var states: [SignInViewState] = []
        var cancellables = Set<AnyCancellable>()

        sut.$viewState
            .sink { state in states.append(state) }
            .store(in: &cancellables)

        sut.handle(event: .onPasskeySignInTapped)
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(states.contains { $0.isLoading == true })
        #expect(sut.viewState.isLoading == false)
    }

    @Test("Register passkey event dispatches correct domain action")
    func registerPasskeyDispatchesAction() async throws {
        mockAuthService.registerPasskeyResult = .success(AuthUser.mock)

        var states: [SignInViewState] = []
        var cancellables = Set<AnyCancellable>()

        sut.$viewState
            .sink { state in states.append(state) }
            .store(in: &cancellables)

        sut.handle(event: .registerPasskeyTapped)
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(states.contains { $0.isLoading == true })
        #expect(sut.viewState.isLoading == false)
    }

    // MARK: - Loading State Tests

    @Test("Loading state updates correctly during passkey sign-in flow")
    func loadingStatePasskeySignIn() async throws {
        mockAuthService.signInWithPasskeyResult = .success(AuthUser.mock)

        var states: [SignInViewState] = []
        var cancellables = Set<AnyCancellable>()

        sut.$viewState
            .sink { state in states.append(state) }
            .store(in: &cancellables)

        sut.handle(event: .onPasskeySignInTapped)
        try await Task.sleep(nanoseconds: 300_000_000)

        let loadingStates = states.filter { $0.isLoading }
        #expect(!loadingStates.isEmpty)
    }

    @Test("Loading state updates correctly during register passkey flow")
    func loadingStateRegisterPasskey() async throws {
        mockAuthService.registerPasskeyResult = .success(AuthUser.mock)

        var states: [SignInViewState] = []
        var cancellables = Set<AnyCancellable>()

        sut.$viewState
            .sink { state in states.append(state) }
            .store(in: &cancellables)

        sut.handle(event: .registerPasskeyTapped)
        try await Task.sleep(nanoseconds: 300_000_000)

        let loadingStates = states.filter { $0.isLoading }
        #expect(!loadingStates.isEmpty)
    }

    // MARK: - Success Flow Tests

    @Test("Passkey sign-in success clears loading and error")
    func passkeySignInSuccess() async throws {
        mockAuthService.signInWithPasskeyResult = .success(AuthUser.mock)

        sut.handle(event: .onPasskeySignInTapped)
        try await Task.sleep(nanoseconds: 300_000_000)

        let finalState = sut.viewState
        #expect(finalState.isLoading == false)
        #expect(finalState.errorMessage == nil)
    }

    @Test("Register passkey success clears loading and error")
    func registerPasskeySuccess() async throws {
        mockAuthService.registerPasskeyResult = .success(AuthUser.mock)

        sut.handle(event: .registerPasskeyTapped)
        try await Task.sleep(nanoseconds: 300_000_000)

        let finalState = sut.viewState
        #expect(finalState.isLoading == false)
        #expect(finalState.errorMessage == nil)
    }

    // MARK: - Error Flow Tests

    @Test("Passkey sign-in failure shows error")
    func passkeySignInFailure() async throws {
        mockAuthService.signInWithPasskeyResult = .failure(AuthError.noPasskeysAvailable)

        sut.handle(event: .onPasskeySignInTapped)
        try await Task.sleep(nanoseconds: 300_000_000)

        let finalState = sut.viewState
        #expect(finalState.isLoading == false)
        #expect(finalState.errorMessage != nil)
    }

    @Test("No passkeys available shows error message")
    func noPasskeysAvailableError() async throws {
        mockAuthService.signInWithPasskeyResult = .failure(AuthError.noPasskeysAvailable)

        sut.handle(event: .onPasskeySignInTapped)
        try await Task.sleep(nanoseconds: 300_000_000)

        let finalState = sut.viewState
        #expect(finalState.isLoading == false)
        #expect(finalState.errorMessage != nil)
    }

    @Test("Passkey sign-in cancelled does not show error")
    func passkeySignInCancelled() async throws {
        mockAuthService.signInWithPasskeyResult = .failure(AuthError.signInCancelled)

        sut.handle(event: .onPasskeySignInTapped)
        try await Task.sleep(nanoseconds: 300_000_000)

        let finalState = sut.viewState
        #expect(finalState.isLoading == false)
        #expect(finalState.errorMessage == nil)
    }

    @Test("Register passkey failure shows error")
    func registerPasskeyFailure() async throws {
        mockAuthService.registerPasskeyResult = .failure(AuthError.unknown("Registration failed"))

        sut.handle(event: .registerPasskeyTapped)
        try await Task.sleep(nanoseconds: 300_000_000)

        let finalState = sut.viewState
        #expect(finalState.isLoading == false)
        #expect(finalState.errorMessage != nil)
    }

    // MARK: - View State Transformation Tests

    @Test("View state reflects domain state loading during passkey flow")
    func viewStateReflectsPasskeyLoading() async throws {
        mockAuthService.signInWithPasskeyResult = .success(AuthUser.mock)

        var states: [SignInViewState] = []
        var cancellables = Set<AnyCancellable>()

        sut.$viewState
            .sink { state in states.append(state) }
            .store(in: &cancellables)

        sut.handle(event: .onPasskeySignInTapped)
        try await Task.sleep(nanoseconds: 300_000_000)

        let loadingStates = states.filter { $0.isLoading }
        #expect(!loadingStates.isEmpty)
    }

    @Test("View state error message set on passkey failure")
    func viewStateErrorOnPasskeyFailure() async throws {
        mockAuthService.signInWithPasskeyResult = .failure(AuthError.noPasskeysAvailable)

        sut.handle(event: .onPasskeySignInTapped)
        try await Task.sleep(nanoseconds: 300_000_000)

        let finalState = sut.viewState
        #expect(finalState.errorMessage != nil)
    }
}
