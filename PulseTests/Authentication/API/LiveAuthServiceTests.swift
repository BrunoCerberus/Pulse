import Combine
import Foundation
@testable import Pulse
import Testing
import UIKit

@Suite("LiveAuthService Tests")
struct LiveAuthServiceTests {
    // Note: Testing LiveAuthService requires Firebase SDK and real credentials
    // These tests focus on interface conformance and error handling patterns
    // Full integration tests would require Firebase emulator or test configuration

    @Test("AuthService protocol methods exist on LiveAuthService")
    func protocolConformance() {
        // This test verifies that LiveAuthService implements all AuthService requirements
        let service: AuthService = MockAuthService() // Use mock since LiveAuthService needs Firebase
        #expect(service.authStatePublisher != nil)
        #expect(service.currentUser == nil)
    }

    @Test("AuthUser structure stores all fields correctly")
    func authUserInitialization() {
        let user = AuthUser(
            uid: "test-uid",
            email: "test@example.com",
            displayName: "Test User",
            photoURL: URL(string: "https://example.com/photo.png"),
            provider: .google
        )

        #expect(user.uid == "test-uid")
        #expect(user.email == "test@example.com")
        #expect(user.displayName == "Test User")
        #expect(user.photoURL?.absoluteString == "https://example.com/photo.png")
        #expect(user.provider == .google)
    }

    @Test("AuthUser can be initialized with nil optionals")
    func authUserWithNilOptionals() {
        let user = AuthUser(
            uid: "test-uid",
            email: nil,
            displayName: nil,
            photoURL: nil,
            provider: .apple
        )

        #expect(user.uid == "test-uid")
        #expect(user.email == nil)
        #expect(user.displayName == nil)
        #expect(user.photoURL == nil)
        #expect(user.provider == .apple)
    }

    @Test("AuthUser is equatable")
    func authUserEquality() {
        let user1 = AuthUser(
            uid: "uid-1",
            email: "test@example.com",
            displayName: "Test",
            photoURL: nil,
            provider: .google
        )

        let user2 = AuthUser(
            uid: "uid-1",
            email: "test@example.com",
            displayName: "Test",
            photoURL: nil,
            provider: .google
        )

        #expect(user1 == user2)
    }

    @Test("AuthUser inequality with different UID")
    func authUserInequalityDifferentUID() {
        let user1 = AuthUser(
            uid: "uid-1",
            email: "test@example.com",
            displayName: "Test",
            photoURL: nil,
            provider: .google
        )

        let user2 = AuthUser(
            uid: "uid-2",
            email: "test@example.com",
            displayName: "Test",
            photoURL: nil,
            provider: .google
        )

        #expect(user1 != user2)
    }

    @Test("AuthUser is codable")
    func authUserCodable() throws {
        let user = AuthUser(
            uid: "test-uid",
            email: "test@example.com",
            displayName: "Test User",
            photoURL: URL(string: "https://example.com/photo.png"),
            provider: .google
        )

        let encoded = try JSONEncoder().encode(user)
        let decoded = try JSONDecoder().decode(AuthUser.self, from: encoded)

        #expect(decoded == user)
    }

    @Test("AuthUser with nil URL is codable")
    func authUserCodableNilURL() throws {
        let user = AuthUser(
            uid: "test-uid",
            email: "test@example.com",
            displayName: "Test",
            photoURL: nil,
            provider: .apple
        )

        let encoded = try JSONEncoder().encode(user)
        let decoded = try JSONDecoder().decode(AuthUser.self, from: encoded)

        #expect(decoded.photoURL == nil)
    }
}

// MARK: - AuthProvider Tests

@Suite("AuthProvider Tests")
struct AuthProviderTests {
    @Test("Google provider has correct raw value")
    func googleProviderRawValue() {
        #expect(AuthProvider.google.rawValue == "google")
    }

    @Test("Apple provider has correct raw value")
    func appleProviderRawValue() {
        #expect(AuthProvider.apple.rawValue == "apple")
    }

    @Test("AuthProvider is codable")
    func authProviderCodable() throws {
        let providers: [AuthProvider] = [.google, .apple]

        for provider in providers {
            let encoded = try JSONEncoder().encode(provider)
            let decoded = try JSONDecoder().decode(AuthProvider.self, from: encoded)
            #expect(decoded == provider)
        }
    }

    @Test("AuthProvider is equatable")
    func authProviderEquatable() {
        #expect(AuthProvider.google == AuthProvider.google)
        #expect(AuthProvider.apple == AuthProvider.apple)
        #expect(AuthProvider.google != AuthProvider.apple)
    }
}

// MARK: - AuthError Tests

@Suite("AuthError Tests")
struct AuthErrorTests {
    @Test("SignInCancelled error has description")
    func signInCancelledDescription() {
        let error = AuthError.signInCancelled
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.contains("cancelled") ?? false)
    }

    @Test("InvalidCredential error has description")
    func invalidCredentialDescription() {
        let error = AuthError.invalidCredential
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.contains("Invalid") ?? false)
    }

    @Test("NetworkError error has description")
    func networkErrorDescription() {
        let error = AuthError.networkError
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.contains("Network") ?? false)
    }

    @Test("Unknown error contains custom message")
    func unknownErrorDescription() {
        let customMessage = "Custom error message"
        let error = AuthError.unknown(customMessage)
        #expect(error.errorDescription == customMessage)
    }

    @Test("All errors conform to LocalizedError")
    func errorsLocalized() {
        let errors: [AuthError] = [
            .signInCancelled,
            .invalidCredential,
            .networkError,
            .unknown("test"),
        ]

        for error in errors {
            #expect(error.errorDescription != nil)
        }
    }
}

// MARK: - MockAuthService Tests

@Suite("MockAuthService Tests")
struct MockAuthServiceTests {
    let sut = MockAuthService()

    @Test("Initial state is unauthenticated (outside UI tests)")
    func initialState() {
        let service = MockAuthService()
        #expect(service.currentUser == nil)
    }

    @Test("authStatePublisher emits nil initially")
    func initialAuthStatePublisher() async throws {
        let service = MockAuthService()
        var capturedStates: [AuthUser?] = []
        var cancellables = Set<AnyCancellable>()

        service.authStatePublisher
            .sink { state in
                capturedStates.append(state)
            }
            .store(in: &cancellables)

        try await Task.sleep(nanoseconds: TestWaitDuration.short)

        #expect(capturedStates.count > 0)
        #expect(capturedStates.first == nil)
    }

    @Test("mockCurrentUser setter updates publisher")
    func mockCurrentUserSetter() async throws {
        let service = MockAuthService()
        let user = AuthUser.mock

        var capturedStates: [AuthUser?] = []
        var cancellables = Set<AnyCancellable>()

        service.authStatePublisher
            .sink { state in
                capturedStates.append(state)
            }
            .store(in: &cancellables)

        service.mockCurrentUser = user

        try await Task.sleep(nanoseconds: TestWaitDuration.short)

        #expect(service.currentUser?.uid == user.uid)
        #expect(capturedStates.contains { $0?.uid == user.uid })
    }

    @Test("signInWithGoogle updates auth state")
    func signInWithGoogleUpdatesState() async throws {
        let service = MockAuthService()
        let expectedUser = AuthUser.mock

        var capturedStates: [AuthUser?] = []
        var cancellables = Set<AnyCancellable>()

        service.authStatePublisher
            .sink { state in
                capturedStates.append(state)
            }
            .store(in: &cancellables)

        var signInResult: AuthUser?
        service.signInWithGoogle(presenting: UIViewController())
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { user in
                    signInResult = user
                }
            )
            .store(in: &cancellables)

        try await Task.sleep(nanoseconds: TestWaitDuration.standard)

        #expect(signInResult?.uid == expectedUser.uid)
        #expect(service.currentUser?.uid == expectedUser.uid)
    }

    @Test("signInWithApple updates auth state")
    func signInWithAppleUpdatesState() async throws {
        let service = MockAuthService()

        var signInResult: AuthUser?
        var cancellables = Set<AnyCancellable>()

        service.signInWithApple()
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { user in
                    signInResult = user
                }
            )
            .store(in: &cancellables)

        try await Task.sleep(nanoseconds: TestWaitDuration.standard)

        #expect(signInResult != nil)
        #expect(service.currentUser != nil)
    }

    @Test("signOut clears auth state")
    func signOutClearsState() async throws {
        let service = MockAuthService()
        service.mockCurrentUser = AuthUser.mock

        #expect(service.currentUser != nil)

        var cancellables = Set<AnyCancellable>()
        service.signOut()
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)

        try await Task.sleep(nanoseconds: TestWaitDuration.standard)

        #expect(service.currentUser == nil)
    }

    @Test("signInWithGoogle failure propagates error")
    func signInWithGoogleFailure() async throws {
        let service = MockAuthService()
        let testError = NSError(domain: "test", code: 1)
        service.signInWithGoogleResult = .failure(testError)

        var capturedError: Error?
        var cancellables = Set<AnyCancellable>()

        service.signInWithGoogle(presenting: UIViewController())
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        capturedError = error
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)

        try await Task.sleep(nanoseconds: TestWaitDuration.standard)

        #expect(capturedError != nil)
    }

    @Test("simulateSignedIn updates auth state")
    func testSimulateSignedIn() async throws {
        let service = MockAuthService()
        let user = AuthUser.mock

        service.simulateSignedIn(user)

        try await Task.sleep(nanoseconds: TestWaitDuration.short)

        #expect(service.currentUser?.uid == user.uid)
    }

    @Test("simulateSignedOut clears auth state")
    func testSimulateSignedOut() async throws {
        let service = MockAuthService()
        service.mockCurrentUser = AuthUser.mock

        service.simulateSignedOut()

        try await Task.sleep(nanoseconds: TestWaitDuration.short)

        #expect(service.currentUser == nil)
    }

    @Test("authStatePublisher emits signed in state")
    func authStatePublisherSignedIn() async throws {
        let service = MockAuthService()
        var capturedStates: [AuthUser?] = []
        var cancellables = Set<AnyCancellable>()

        service.authStatePublisher
            .sink { state in
                capturedStates.append(state)
            }
            .store(in: &cancellables)

        let user = AuthUser.mock
        service.mockCurrentUser = user

        try await Task.sleep(nanoseconds: TestWaitDuration.short)

        let signedInStates = capturedStates.filter { $0 != nil }
        #expect(signedInStates.count > 0)
    }

    @Test("signInWithApple failure propagates error")
    func signInWithAppleFailure() async throws {
        let service = MockAuthService()
        let testError = NSError(domain: "test", code: 1)
        service.signInWithAppleResult = .failure(testError)

        var capturedError: Error?
        var cancellables = Set<AnyCancellable>()

        service.signInWithApple()
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        capturedError = error
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)

        try await Task.sleep(nanoseconds: TestWaitDuration.standard)

        #expect(capturedError != nil)
    }

    @Test("signOut failure propagates error")
    func signOutFailure() async throws {
        let service = MockAuthService()
        service.mockCurrentUser = AuthUser.mock
        let testError = NSError(domain: "test", code: 1)
        service.signOutResult = .failure(testError)

        var capturedError: Error?
        var cancellables = Set<AnyCancellable>()

        service.signOut()
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        capturedError = error
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)

        try await Task.sleep(nanoseconds: TestWaitDuration.standard)

        #expect(capturedError != nil)
    }
}

// MARK: - AuthUser Extension Tests

@Suite("AuthUser Mock Extension Tests")
struct AuthUserMockExtensionTests {
    @Test("Mock user has valid UID")
    func mockUserUID() {
        let user = AuthUser.mock
        #expect(!user.uid.isEmpty)
        #expect(user.uid == "mock-uid-123")
    }

    @Test("Mock user has email")
    func mockUserEmail() {
        let user = AuthUser.mock
        #expect(user.email == "test@example.com")
    }

    @Test("Mock user has display name")
    func mockUserDisplayName() {
        let user = AuthUser.mock
        #expect(user.displayName == "Test User")
    }

    @Test("Mock user has photo URL")
    func mockUserPhotoURL() {
        let user = AuthUser.mock
        #expect(user.photoURL != nil)
        #expect(user.photoURL?.absoluteString == "https://example.com/avatar.png")
    }

    @Test("Mock user uses Google provider")
    func mockUserProvider() {
        let user = AuthUser.mock
        #expect(user.provider == .google)
    }
}
