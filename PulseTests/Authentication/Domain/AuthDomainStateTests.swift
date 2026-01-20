import Foundation
@testable import Pulse
import Testing

@Suite("AuthDomainState Initialization Tests")
struct AuthDomainStateInitializationTests {
    @Test("Initial isLoading is false")
    func initialIsLoadingFalse() {
        let state = AuthDomainState()
        #expect(!state.isLoading)
    }

    @Test("Initial error is nil")
    func initialErrorNil() {
        let state = AuthDomainState()
        #expect(state.error == nil)
    }

    @Test("Initial user is nil")
    func initialUserNil() {
        let state = AuthDomainState()
        #expect(state.user == nil)
    }

    @Test("Initial state is unauthenticated")
    func initialStateUnauthenticated() {
        let state = AuthDomainState()
        #expect(!state.isLoading)
        #expect(state.error == nil)
        #expect(state.user == nil)
    }
}

@Suite("AuthDomainState Loading Tests")
struct AuthDomainStateLoadingTests {
    @Test("Can set isLoading to true")
    func setIsLoadingTrue() {
        var state = AuthDomainState()
        state.isLoading = true
        #expect(state.isLoading)
    }

    @Test("Can set isLoading to false")
    func setIsLoadingFalse() {
        var state = AuthDomainState()
        state.isLoading = true
        state.isLoading = false
        #expect(!state.isLoading)
    }

    @Test("Can toggle isLoading flag")
    func toggleIsLoading() {
        var state = AuthDomainState()
        #expect(!state.isLoading)
        state.isLoading = true
        #expect(state.isLoading)
        state.isLoading = false
        #expect(!state.isLoading)
    }

    @Test("isLoading independent from user")
    func isLoadingIndependentFromUser() {
        var state = AuthDomainState()
        state.isLoading = true
        let user = AuthUser(id: "123", email: "test@example.com", name: "Test User", provider: .google)
        state.user = user

        #expect(state.isLoading)
        #expect(state.user != nil)
    }
}

@Suite("AuthDomainState Error Tests")
struct AuthDomainStateErrorTests {
    @Test("Can set error message")
    func setErrorMessage() {
        var state = AuthDomainState()
        state.error = "Authentication failed"
        #expect(state.error == "Authentication failed")
    }

    @Test("Can clear error message")
    func clearErrorMessage() {
        var state = AuthDomainState()
        state.error = "Error"
        state.error = nil
        #expect(state.error == nil)
    }

    @Test("Can change error message")
    func changeErrorMessage() {
        var state = AuthDomainState()
        state.error = "Error 1"
        state.error = "Error 2"
        #expect(state.error == "Error 2")
    }

    @Test("Error can be empty string")
    func emptyErrorString() {
        var state = AuthDomainState()
        state.error = ""
        #expect(state.error == "")
    }

    @Test("Error independent from loading and user")
    func errorIndependentFromLoadingAndUser() {
        var state = AuthDomainState()
        state.isLoading = true
        state.error = "Error occurred"
        let user = AuthUser(id: "123", email: "test@example.com", name: "Test", provider: .apple)
        state.user = user

        #expect(state.isLoading)
        #expect(state.error == "Error occurred")
        #expect(state.user != nil)
    }
}

@Suite("AuthDomainState User Tests")
struct AuthDomainStateUserTests {
    @Test("Can set user")
    func setUser() {
        var state = AuthDomainState()
        let user = AuthUser(id: "123", email: "test@example.com", name: "Test User", provider: .google)
        state.user = user
        #expect(state.user == user)
    }

    @Test("Can clear user")
    func clearUser() {
        var state = AuthDomainState()
        let user = AuthUser(id: "123", email: "test@example.com", name: "Test User", provider: .google)
        state.user = user
        state.user = nil
        #expect(state.user == nil)
    }

    @Test("Can change user")
    func changeUser() {
        var state = AuthDomainState()
        let user1 = AuthUser(id: "123", email: "test1@example.com", name: "User 1", provider: .google)
        let user2 = AuthUser(id: "456", email: "test2@example.com", name: "User 2", provider: .apple)

        state.user = user1
        #expect(state.user == user1)

        state.user = user2
        #expect(state.user == user2)
    }

    @Test("User with Google provider")
    func userWithGoogleProvider() {
        var state = AuthDomainState()
        let user = AuthUser(id: "google-123", email: "user@gmail.com", name: "Google User", provider: .google)
        state.user = user

        #expect(state.user?.provider == .google)
        #expect(state.user?.email == "user@gmail.com")
    }

    @Test("User with Apple provider")
    func userWithAppleProvider() {
        var state = AuthDomainState()
        let user = AuthUser(id: "apple-123", email: "user@icloud.com", name: "Apple User", provider: .apple)
        state.user = user

        #expect(state.user?.provider == .apple)
        #expect(state.user?.email == "user@icloud.com")
    }

    @Test("Multiple users can be set sequentially")
    func multipleUsersSequentially() {
        var state = AuthDomainState()

        for index in 1 ... 5 {
            let user = AuthUser(
                id: "user-\(i)",
                email: "user\(i)@example.com",
                name: "User \(i)",
                provider: i % 2 == 0 ? .google : .apple
            )
            state.user = user
            #expect(state.user?.id == "user-\(i)")
        }
    }
}

@Suite("AuthDomainState Sign-In Flow Tests")
struct AuthDomainStateSignInFlowTests {
    @Test("Simulate Google sign-in flow")
    func googleSignInFlow() {
        var state = AuthDomainState()
        state.isLoading = true
        state.error = nil

        let user = AuthUser(
            id: "google-123",
            email: "user@gmail.com",
            name: "Google User",
            provider: .google
        )
        state.user = user
        state.isLoading = false

        #expect(!state.isLoading)
        #expect(state.error == nil)
        #expect(state.user?.provider == .google)
    }

    @Test("Simulate Apple sign-in flow")
    func appleSignInFlow() {
        var state = AuthDomainState()
        state.isLoading = true

        let user = AuthUser(
            id: "apple-123",
            email: "user@icloud.com",
            name: "Apple User",
            provider: .apple
        )
        state.user = user
        state.isLoading = false

        #expect(!state.isLoading)
        #expect(state.user?.provider == .apple)
    }

    @Test("Simulate sign-in error")
    func signInError() {
        var state = AuthDomainState()
        state.isLoading = true
        state.error = "Failed to sign in"
        state.isLoading = false

        #expect(!state.isLoading)
        #expect(state.error == "Failed to sign in")
        #expect(state.user == nil)
    }

    @Test("Simulate sign-in retry after error")
    func signInRetryAfterError() {
        var state = AuthDomainState()

        // First attempt fails
        state.isLoading = true
        state.error = "Network error"
        state.isLoading = false
        #expect(state.error == "Network error")

        // Clear error and retry
        state.error = nil
        state.isLoading = true
        let user = AuthUser(
            id: "123",
            email: "user@example.com",
            name: "User",
            provider: .google
        )
        state.user = user
        state.isLoading = false

        #expect(state.error == nil)
        #expect(state.user != nil)
    }
}

@Suite("AuthDomainState Sign-Out Flow Tests")
struct AuthDomainStateSignOutFlowTests {
    @Test("Simulate sign-out flow")
    func signOutFlow() {
        var state = AuthDomainState()

        // User signed in
        let user = AuthUser(
            id: "123",
            email: "user@example.com",
            name: "User",
            provider: .google
        )
        state.user = user
        #expect(state.user != nil)

        // Sign out
        state.isLoading = true
        state.user = nil
        state.isLoading = false

        #expect(!state.isLoading)
        #expect(state.user == nil)
    }

    @Test("Simulate sign-out error")
    func signOutError() {
        var state = AuthDomainState()
        let user = AuthUser(
            id: "123",
            email: "user@example.com",
            name: "User",
            provider: .google
        )
        state.user = user

        state.isLoading = true
        state.error = "Failed to sign out"
        state.isLoading = false

        #expect(!state.isLoading)
        #expect(state.error == "Failed to sign out")
        #expect(state.user != nil)
    }
}

@Suite("AuthDomainState Equatable Tests")
struct AuthDomainStateEquatableTests {
    @Test("Two initial states are equal")
    func twoInitialStatesEqual() {
        let state1 = AuthDomainState()
        let state2 = AuthDomainState()
        #expect(state1 == state2)
    }

    @Test("States with different isLoading are not equal")
    func differentIsLoadingNotEqual() {
        var state1 = AuthDomainState()
        var state2 = AuthDomainState()
        state1.isLoading = true
        #expect(state1 != state2)
    }

    @Test("States with different errors are not equal")
    func differentErrorNotEqual() {
        var state1 = AuthDomainState()
        var state2 = AuthDomainState()
        state1.error = "Error"
        #expect(state1 != state2)
    }

    @Test("States with different users are not equal")
    func differentUserNotEqual() {
        var state1 = AuthDomainState()
        var state2 = AuthDomainState()
        let user = AuthUser(
            id: "123",
            email: "test@example.com",
            name: "Test",
            provider: .google
        )
        state1.user = user
        #expect(state1 != state2)
    }

    @Test("States with same user are equal")
    func sameUserEqual() {
        var state1 = AuthDomainState()
        var state2 = AuthDomainState()
        let user = AuthUser(
            id: "123",
            email: "test@example.com",
            name: "Test",
            provider: .google
        )
        state1.user = user
        state2.user = user
        #expect(state1 == state2)
    }

    @Test("States become equal after same mutations")
    func statesEqualAfterSameMutations() {
        var state1 = AuthDomainState()
        var state2 = AuthDomainState()
        let user = AuthUser(
            id: "123",
            email: "test@example.com",
            name: "Test",
            provider: .apple
        )
        state1.user = user
        state2.user = user
        state1.isLoading = false
        state2.isLoading = false
        #expect(state1 == state2)
    }
}

@Suite("AuthDomainState Complex Authentication Scenarios")
struct AuthDomainStateComplexAuthScenarioTests {
    @Test("Simulate complete authentication lifecycle")
    func completeAuthenticationLifecycle() {
        var state = AuthDomainState()
        #expect(!state.isLoading)
        #expect(state.user == nil)

        // Sign in
        state.isLoading = true
        let user = AuthUser(
            id: "123",
            email: "user@example.com",
            name: "User",
            provider: .google
        )
        state.user = user
        state.isLoading = false

        #expect(!state.isLoading)
        #expect(state.user != nil)

        // Sign out
        state.isLoading = true
        state.user = nil
        state.isLoading = false

        #expect(!state.isLoading)
        #expect(state.user == nil)
    }

    @Test("Simulate authentication error recovery")
    func authenticationErrorRecovery() {
        var state = AuthDomainState()

        // Attempt 1: Error
        state.isLoading = true
        state.error = "Network connection failed"
        state.isLoading = false
        #expect(state.error == "Network connection failed")
        #expect(state.user == nil)

        // Clear error
        state.error = nil

        // Attempt 2: Success
        state.isLoading = true
        let user = AuthUser(
            id: "123",
            email: "user@example.com",
            name: "User",
            provider: .apple
        )
        state.user = user
        state.isLoading = false

        #expect(state.error == nil)
        #expect(state.user != nil)
    }

    @Test("Simulate user provider switching")
    func userProviderSwitching() {
        var state = AuthDomainState()

        // Sign in with Google
        let googleUser = AuthUser(
            id: "google-123",
            email: "user@gmail.com",
            name: "User",
            provider: .google
        )
        state.user = googleUser
        #expect(state.user?.provider == .google)

        // Switch to Apple (sign out then sign in with Apple)
        state.user = nil
        let appleUser = AuthUser(
            id: "apple-456",
            email: "user@icloud.com",
            name: "User",
            provider: .apple
        )
        state.user = appleUser
        #expect(state.user?.provider == .apple)
    }

    @Test("Simulate session restoration")
    func sessionRestoration() {
        var state = AuthDomainState()

        // User previously signed in
        let existingUser = AuthUser(
            id: "123",
            email: "user@example.com",
            name: "User",
            provider: .google
        )
        state.isLoading = true
        state.user = existingUser
        state.isLoading = false

        #expect(!state.isLoading)
        #expect(state.user == existingUser)
    }

    @Test("Simulate authentication with multiple retries")
    func authenticationWithMultipleRetries() {
        var state = AuthDomainState()

        for index in 1 ... 3 {
            state.isLoading = true
            if i < 3 {
                state.error = "Attempt \(i) failed"
                state.isLoading = false
                state.error = nil
            } else {
                let user = AuthUser(
                    id: "123",
                    email: "user@example.com",
                    name: "User",
                    provider: .google
                )
                state.user = user
                state.isLoading = false
            }
        }

        #expect(state.user != nil)
        #expect(state.error == nil)
    }
}
