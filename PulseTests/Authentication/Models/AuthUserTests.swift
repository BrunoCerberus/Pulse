import Foundation
@testable import Pulse
import Testing

@Suite("AuthUser Model Tests")
struct AuthUserTests {
    // MARK: - Initialization Tests

    @Test("AuthUser initializes with all properties")
    func initializesWithAllProperties() {
        let photoURL = URL(string: "https://example.com/photo.jpg")
        let user = AuthUser(
            uid: "test-uid-123",
            email: "test@example.com",
            displayName: "John Doe",
            photoURL: photoURL,
            provider: .google
        )

        #expect(user.uid == "test-uid-123")
        #expect(user.email == "test@example.com")
        #expect(user.displayName == "John Doe")
        #expect(user.photoURL == photoURL)
        #expect(user.provider == .google)
    }

    @Test("AuthUser with nil optional properties")
    func initializesWithNilOptionals() {
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
    }

    // MARK: - Codable Tests

    @Test("AuthUser encodes and decodes correctly")
    func encodesAndDecodesCorrectly() throws {
        let originalUser = AuthUser(
            uid: "encode-test-uid",
            email: "encode@test.com",
            displayName: "Test User",
            photoURL: URL(string: "https://example.com/photo.jpg"),
            provider: .google
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(originalUser)

        let decoder = JSONDecoder()
        let decodedUser = try decoder.decode(AuthUser.self, from: data)

        #expect(decodedUser == originalUser)
        #expect(decodedUser.uid == originalUser.uid)
        #expect(decodedUser.email == originalUser.email)
        #expect(decodedUser.displayName == originalUser.displayName)
        #expect(decodedUser.photoURL == originalUser.photoURL)
        #expect(decodedUser.provider == originalUser.provider)
    }

    @Test("AuthUser decodes with nil optionals")
    func decodesWithNilOptionals() throws {
        let user = AuthUser(
            uid: "minimal-uid",
            email: nil,
            displayName: nil,
            photoURL: nil,
            provider: .apple
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(user)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AuthUser.self, from: data)

        #expect(decoded.email == nil)
        #expect(decoded.displayName == nil)
        #expect(decoded.photoURL == nil)
    }

    // MARK: - Equatable Tests

    @Test("AuthUser equality comparison")
    func equalityComparison() {
        let user1 = AuthUser(
            uid: "same-uid",
            email: "same@email.com",
            displayName: "Same Name",
            photoURL: nil,
            provider: .google
        )

        let user2 = AuthUser(
            uid: "same-uid",
            email: "same@email.com",
            displayName: "Same Name",
            photoURL: nil,
            provider: .google
        )

        let user3 = AuthUser(
            uid: "different-uid",
            email: "same@email.com",
            displayName: "Same Name",
            photoURL: nil,
            provider: .google
        )

        #expect(user1 == user2)
        #expect(user1 != user3)
    }
}

@Suite("AuthProvider Tests")
struct AuthProviderTests {
    @Test("AuthProvider google has correct raw value")
    func googleRawValue() {
        let provider = AuthProvider.google

        #expect(provider.rawValue == "google")
    }

    @Test("AuthProvider apple has correct raw value")
    func appleRawValue() {
        let provider = AuthProvider.apple

        #expect(provider.rawValue == "apple")
    }

    @Test("AuthProvider encodes and decodes")
    func encodesAndDecodes() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        // Test Google provider
        let googleData = try encoder.encode(AuthProvider.google)
        let decodedGoogle = try decoder.decode(AuthProvider.self, from: googleData)
        #expect(decodedGoogle == .google)

        // Test Apple provider
        let appleData = try encoder.encode(AuthProvider.apple)
        let decodedApple = try decoder.decode(AuthProvider.self, from: appleData)
        #expect(decodedApple == .apple)
    }

    @Test("AuthProvider equality")
    func equalityComparison() {
        #expect(AuthProvider.google == AuthProvider.google)
        #expect(AuthProvider.apple == AuthProvider.apple)
        #expect(AuthProvider.google != AuthProvider.apple)
    }
}

@Suite("AuthError Tests")
struct AuthErrorTests {
    @Test("AuthError signInCancelled has localized description")
    func signInCancelledDescription() {
        let error = AuthError.signInCancelled

        #expect(error.errorDescription == "Sign in was cancelled")
    }

    @Test("AuthError invalidCredential has localized description")
    func invalidCredentialDescription() {
        let error = AuthError.invalidCredential

        #expect(error.errorDescription == "Invalid credentials")
    }

    @Test("AuthError networkError has localized description")
    func networkErrorDescription() {
        let error = AuthError.networkError

        #expect(error.errorDescription == "Network error occurred")
    }

    @Test("AuthError unknown has localized description with message")
    func unknownErrorDescription() {
        let error = AuthError.unknown("Custom error message")

        #expect(error.errorDescription == "Custom error message")
    }

    @Test("AuthError conforms to LocalizedError")
    func conformsToLocalizedError() {
        let error: LocalizedError = AuthError.signInCancelled

        #expect(error.errorDescription != nil)
    }

    @Test("AuthError conforms to Error")
    func conformsToError() {
        let error: Error = AuthError.signInCancelled

        #expect(error is AuthError)
    }

    @Test("AuthError cases are distinct")
    func casesAreDistinct() {
        let cancelled = AuthError.signInCancelled
        let invalid = AuthError.invalidCredential
        let network = AuthError.networkError
        let unknown1 = AuthError.unknown("error1")
        let unknown2 = AuthError.unknown("error2")

        // Each error type should have a unique description
        #expect(cancelled.errorDescription != invalid.errorDescription)
        #expect(cancelled.errorDescription != network.errorDescription)
        #expect(unknown1.errorDescription != unknown2.errorDescription)
    }
}
