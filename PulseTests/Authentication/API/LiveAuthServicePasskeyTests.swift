import Combine
@testable import Pulse
import Testing

@Suite("LiveAuthService Passkey Tests")
@MainActor
struct LiveAuthServicePasskeyTests {
    let mockService: MockAuthService

    init() {
        mockService = MockAuthService()
    }

    // MARK: - Sign In With Passkey Tests

    @Test("signInWithPasskey success sets currentUser")
    func signInWithPasskeySuccess() async throws {
        let expectedUser = AuthUser.mock
        mockService.signInWithPasskeyResult = .success(expectedUser)

        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(mockService.currentUser == expectedUser)
    }

    @Test("signInWithPasskey failure does not set user")
    func signInWithPasskeyFailure() async throws {
        mockService.signInWithPasskeyResult = .failure(AuthError.noPasskeysAvailable)

        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(mockService.currentUser == nil)
    }

    // MARK: - Register Passkey Tests

    @Test("registerPasskey success sets currentUser")
    func registerPasskeySuccess() async throws {
        let expectedUser = AuthUser.mock
        mockService.registerPasskeyResult = .success(expectedUser)

        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(mockService.currentUser == expectedUser)
    }

    @Test("registerPasskey failure does not set user")
    func registerPasskeyFailure() async throws {
        mockService.registerPasskeyResult = .failure(AuthError.unknown("Registration failed"))

        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(mockService.currentUser == nil)
    }

    // MARK: - Get Available Passkeys Tests

    @Test("getAvailablePasskeys returns usernames")
    func getAvailablePasskeysReturnsUsernames() async throws {
        let expectedUsernames = ["device-passkey", "backup-key"]
        mockService.getAvailablePasskeysResult = .success(expectedUsernames)

        var receivedUsernames: [String] = []
        var cancellables = Set<AnyCancellable>()

        mockService.getAvailablePasskeys()
            .sink(receiveCompletion: { _ in }, receiveValue: { usernames in receivedUsernames = usernames })
            .store(in: &cancellables)

        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(receivedUsernames == expectedUsernames)
    }

    @Test("getAvailablePasskeys failure publishes error")
    func getAvailablePasskeysFailure() async throws {
        mockService.getAvailablePasskeysResult = .failure(AuthError.unknown("Failed to retrieve passkeys"))

        var errors: [Error] = []
        var cancellables = Set<AnyCancellable>()

        mockService.getAvailablePasskeys()
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    errors.append(error)
                }
            }, receiveValue: { _ in })
            .store(in: &cancellables)

        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(errors.count == 1)
    }

    // MARK: - Delete Passkey Tests

    @Test("deletePasskey success increments call count")
    func deletePasskeySuccess() async throws {
        mockService.deletePasskeyResult = .success(())

        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(mockService.deletePasskeyCallCount == 1)
    }

    @Test("deletePasskey failure publishes error")
    func deletePasskeyFailure() async throws {
        mockService.deletePasskeyResult = .failure(AuthError.unknown("Failed to delete passkey"))

        var errors: [Error] = []
        var cancellables = Set<AnyCancellable>()

        mockService.deletePasskey(username: "device-passkey")
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    errors.append(error)
                }
            }, receiveValue: { _ in })
            .store(in: &cancellables)

        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(errors.count == 1)
    }
}
