import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing
import UIKit

@Suite("AuthDomainInteractor Passkey Tests")
@MainActor
struct AuthDomainInteractorPasskeyTests {
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

    @Test("Initial state has hasPasskey = false")
    func initialStateHasNoPasskey() {
        let state = sut.currentState
        #expect(state.hasPasskey == false)
    }

    // MARK: - Sign In With Passkey Tests

    @Test("Passkey sign-in success sets user and hasPasskey")
    func passkeySignInSuccess() async throws {
        let expectedUser = AuthUser.mock

        mockAuthService.signInWithPasskeyResult = .success(expectedUser)
        var states: [AuthDomainState] = []
        var cancellables = Set<AnyCancellable>()

        sut.statePublisher
            .sink { state in states.append(state) }
            .store(in: &cancellables)

        sut.dispatch(action: .signInWithPasskey)
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(states.contains { $0.isLoading == true })
        #expect(sut.currentState.isLoading == false)
        #expect(sut.currentState.user == expectedUser)
        #expect(sut.currentState.hasPasskey == true)
        #expect(sut.currentState.error == nil)

        let signInEvents = mockAnalyticsService.loggedEvents.filter { $0.name == "sign_in" }
        #expect(signInEvents.count == 1)
        #expect(signInEvents.first?.parameters?["provider"] as? String == "passkey")
        #expect(signInEvents.first?.parameters?["success"] as? Bool == true)
    }

    @Test("Passkey sign-in failure sets error")
    func passkeySignInFailure() async throws {
        mockAuthService.signInWithPasskeyResult = .failure(AuthError.noPasskeysAvailable)

        sut.dispatch(action: .signInWithPasskey)
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.currentState.isLoading == false)
        #expect(sut.currentState.user == nil)
        #expect(sut.currentState.hasPasskey == false)
        #expect(sut.currentState.error != nil)

        let signInEvents = mockAnalyticsService.loggedEvents.filter { $0.name == "sign_in" }
        #expect(signInEvents.count == 1)
        #expect(signInEvents.first?.parameters?["success"] as? Bool == false)
        #expect(mockAnalyticsService.recordedErrors.count == 1)
    }

    @Test("Passkey sign-in cancelled does not set error")
    func passkeySignInCancelled() async throws {
        mockAuthService.signInWithPasskeyResult = .failure(AuthError.signInCancelled)

        sut.dispatch(action: .signInWithPasskey)
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.currentState.isLoading == false)
        #expect(sut.currentState.user == nil)
        #expect(sut.currentState.error == nil)

        let signInEvents = mockAnalyticsService.loggedEvents.filter { $0.name == "sign_in" }
        #expect(signInEvents.isEmpty)
        #expect(mockAnalyticsService.recordedErrors.isEmpty)
    }

    // MARK: - Register Passkey Tests

    @Test("Register passkey success sets hasPasskey and logs event")
    func registerPasskeySuccess() async throws {
        let expectedUser = AuthUser.mock

        mockAuthService.registerPasskeyResult = .success(expectedUser)
        var states: [AuthDomainState] = []
        var cancellables = Set<AnyCancellable>()

        sut.statePublisher
            .sink { state in states.append(state) }
            .store(in: &cancellables)

        sut.dispatch(action: .registerPasskey)
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.currentState.isLoading == false)
        #expect(sut.currentState.hasPasskey == true)
        #expect(sut.currentState.error == nil)

        let registeredEvents = mockAnalyticsService.loggedEvents.filter { $0.name == "passkey_registered" }
        #expect(registeredEvents.count == 1)
    }

    // MARK: - Load Passkeys Tests

    @Test("Load passkeys success sets hasPasskey based on count")
    func loadPasskeysSuccess() async throws {
        mockAuthService.getAvailablePasskeysResult = .success(["device-passkey", "backup-key"])

        var states: [AuthDomainState] = []
        var cancellables = Set<AnyCancellable>()

        sut.statePublisher
            .sink { state in states.append(state) }
            .store(in: &cancellables)

        sut.dispatch(action: .loadPasskeys)
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.currentState.isLoading == false)
        #expect(sut.currentState.hasPasskey == true)
    }

    @Test("Load passkeys with empty list sets hasPasskey to false")
    func loadPasskeysEmptyList() async throws {
        mockAuthService.getAvailablePasskeysResult = .success([])

        var states: [AuthDomainState] = []
        var cancellables = Set<AnyCancellable>()

        sut.statePublisher
            .sink { state in states.append(state) }
            .store(in: &cancellables)

        sut.dispatch(action: .loadPasskeys)
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.currentState.isLoading == false)
        #expect(sut.currentState.hasPasskey == false)
    }

    // MARK: - Delete Passkey Tests

    @Test("Delete passkey success removes flag and clears from list")
    func deletePasskeySuccess() async throws {
        // Start with a user signed in and hasPasskey = true
        mockAuthService.signInWithPasskeyResult = .success(AuthUser.mock)
        sut.dispatch(action: .signInWithPasskey)
        try await Task.sleep(nanoseconds: 300_000_000)
        #expect(sut.currentState.hasPasskey == true)

        // Reset mock for delete
        mockAuthService.deletePasskeyResult = .success(())

        sut.dispatch(action: .deletePasskey(username: "device-passkey"))
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.currentState.isLoading == false)
        #expect(sut.currentState.hasPasskey == false)
        #expect(mockAuthService.deletePasskeyCallCount == 1)

        let deletedEvents = mockAnalyticsService.loggedEvents.filter { $0.name == "passkey_deleted" }
        #expect(deletedEvents.count == 1)
    }

    @Test("Delete passkey failure sets error")
    func deletePasskeyFailure() async throws {
        // Start with a user signed in and hasPasskey = true
        mockAuthService.signInWithPasskeyResult = .success(AuthUser.mock)
        sut.dispatch(action: .signInWithPasskey)
        try await Task.sleep(nanoseconds: 300_000_000)

        // Reset mock for delete failure
        mockAuthService.deletePasskeyResult = .failure(AuthError.unknown("Failed to delete"))

        sut.dispatch(action: .deletePasskey(username: "device-passkey"))
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.currentState.isLoading == false)
        #expect(sut.currentState.error != nil)
    }
}
