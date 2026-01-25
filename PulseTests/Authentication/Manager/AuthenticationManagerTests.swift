import Combine
import Foundation
@testable import Pulse
import Testing

/// Tests for AuthenticationManager singleton covering:
/// - Initial loading state
/// - Configuration with/without authenticated user
/// - Auth state publisher binding
/// - User sign-in and sign-out lifecycle
/// - State equality comparisons
/// - Test isolation with resetForTesting()
///
/// NOTE: Tests use shared singleton with resetForTesting() for isolation.
/// The resetForTesting() method ensures clean state between tests.
/// Tests are serialized to prevent race conditions on the singleton.
@Suite("AuthenticationManager Tests", .serialized)
@MainActor
struct AuthenticationManagerTests {
    let mockAuthService: MockAuthService
    let sut: AuthenticationManager

    init() {
        mockAuthService = MockAuthService()
        // Use shared instance but reset it for testing to ensure isolation
        sut = AuthenticationManager.shared
        sut.resetForTesting()
    }

    @Test("Initial auth state is loading")
    func initialAuthState() {
        // AuthenticationManager singleton starts in loading state
        // This test verifies the initial state before configuration
        #expect(sut.authState == .loading)
        #expect(sut.currentUser == nil)
        #expect(!sut.isAuthenticated)
    }

    @Test("Configure with authenticated user sets state immediately")
    func configureWithAuthenticatedUser() {
        let testUser = AuthUser(
            uid: "test-user-123",
            email: "test@example.com",
            displayName: "Test User",
            photoURL: nil,
            provider: .google
        )
        mockAuthService.mockCurrentUser = testUser

        sut.configure(with: mockAuthService)

        #expect(sut.authState == .authenticated(testUser))
        #expect(sut.currentUser == testUser)
        #expect(sut.isAuthenticated)
    }

    @Test("Configure with no user sets unauthenticated state")
    func configureWithNoUser() {
        mockAuthService.mockCurrentUser = nil

        sut.configure(with: mockAuthService)

        #expect(sut.authState == .unauthenticated)
        #expect(sut.currentUser == nil)
        #expect(!sut.isAuthenticated)
    }

    @Test("Auth state changes are published")
    func authStateChangesArePublished() async {
        mockAuthService.mockCurrentUser = nil
        sut.configure(with: mockAuthService)

        var cancellables = Set<AnyCancellable>()
        var states: [AuthenticationManager.AuthState] = []

        sut.$authState
            .sink { state in
                states.append(state)
            }
            .store(in: &cancellables)

        let testUser = AuthUser(
            uid: "test-user-456",
            email: "user@example.com",
            displayName: "New User",
            photoURL: nil,
            provider: .apple
        )

        // Simulate auth service publishing a new user
        mockAuthService.simulateSignedIn(testUser)

        // Wait for authenticated state to be published
        let success = await waitForCondition {
            states.contains { state in
                if case let .authenticated(user) = state {
                    return user == testUser
                }
                return false
            }
        }

        #expect(success)
    }

    @Test("Auth state publisher emits state changes")
    func authStatePublisherEmitsChanges() async {
        mockAuthService.mockCurrentUser = nil
        sut.configure(with: mockAuthService)

        var cancellables = Set<AnyCancellable>()
        var states: [AuthenticationManager.AuthState] = []

        sut.authStatePublisher
            .sink { state in
                states.append(state)
            }
            .store(in: &cancellables)

        let testUser = AuthUser(
            uid: "test-user-789",
            email: "another@example.com",
            displayName: "Another User",
            photoURL: nil,
            provider: .google
        )

        mockAuthService.simulateSignedIn(testUser)

        // Wait for state changes to be published
        let success = await waitForCondition {
            states.count >= 1
        }

        #expect(success)
    }

    @Test("Logout triggers unauthenticated state")
    func logoutTriggersUnauthenticatedState() async {
        let testUser = AuthUser(
            uid: "test-user-logout",
            email: "logout@example.com",
            displayName: "Logout User",
            photoURL: nil,
            provider: .google
        )
        mockAuthService.mockCurrentUser = testUser
        sut.configure(with: mockAuthService)

        #expect(sut.isAuthenticated)

        // Simulate logout by sending nil
        mockAuthService.simulateSignedOut()

        // Wait for unauthenticated state
        let success = await waitForCondition { [sut] in
            sut.authState == .unauthenticated
        }

        #expect(success)
        #expect(sut.currentUser == nil)
        #expect(!sut.isAuthenticated)
    }

    @Test("Current user is updated when auth state changes")
    func currentUserIsUpdated() async {
        mockAuthService.mockCurrentUser = nil
        sut.configure(with: mockAuthService)

        #expect(sut.currentUser == nil)

        let testUser = AuthUser(
            uid: "test-user-update",
            email: "update@example.com",
            displayName: "Update User",
            photoURL: nil,
            provider: .apple
        )

        mockAuthService.simulateSignedIn(testUser)

        // Wait for current user to be updated
        let success = await waitForCondition { [sut] in
            sut.currentUser == testUser
        }

        #expect(success)
    }

    @Test("isAuthenticated returns correct value for different states")
    func isAuthenticatedCorrectValue() {
        // Test loading state
        sut.setUnauthenticatedForTesting()
        #expect(!sut.isAuthenticated)

        // Test authenticated state
        let testUser = AuthUser(
            uid: "test-user-auth-check",
            email: "authcheck@example.com",
            displayName: "Auth Check User",
            photoURL: nil,
            provider: .google
        )
        sut.setAuthenticatedForTesting(testUser)
        #expect(sut.isAuthenticated)

        // Test unauthenticated state
        sut.setUnauthenticatedForTesting()
        #expect(!sut.isAuthenticated)
    }

    @Test("Auth state equality works correctly")
    func authStateEquality() {
        let user1 = AuthUser(
            uid: "user-1",
            email: "user1@example.com",
            displayName: "User 1",
            photoURL: nil,
            provider: .google
        )
        let user2 = AuthUser(
            uid: "user-2",
            email: "user2@example.com",
            displayName: "User 2",
            photoURL: nil,
            provider: .apple
        )

        #expect(AuthenticationManager.AuthState.loading == AuthenticationManager.AuthState.loading)
        #expect(
            AuthenticationManager.AuthState.unauthenticated == AuthenticationManager.AuthState
                .unauthenticated
        )
        #expect(
            AuthenticationManager.AuthState.authenticated(user1) == AuthenticationManager.AuthState
                .authenticated(user1)
        )
        #expect(
            AuthenticationManager.AuthState.authenticated(user1) != AuthenticationManager.AuthState
                .authenticated(user2)
        )
        #expect(
            AuthenticationManager.AuthState.loading != AuthenticationManager.AuthState.unauthenticated
        )
    }

    @Test("Testing helpers set state correctly")
    func helpersSetState() {
        let testUser = AuthUser(
            uid: "test-helper-user",
            email: "helper@example.com",
            displayName: "Helper User",
            photoURL: nil,
            provider: .google
        )

        sut.setAuthenticatedForTesting(testUser)
        #expect(sut.authState == .authenticated(testUser))
        #expect(sut.currentUser == testUser)

        sut.setUnauthenticatedForTesting()
        #expect(sut.authState == .unauthenticated)
        #expect(sut.currentUser == nil)
    }
}
