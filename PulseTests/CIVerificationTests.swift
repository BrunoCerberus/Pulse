import Foundation
@testable import Pulse
import Testing

/// Temporary test file to verify CI failure logging works correctly.
/// DELETE THIS FILE after verifying the CI enhancement.
@Suite("CI Verification Tests - DELETE AFTER VERIFICATION")
struct CIVerificationTests {
    @Test("This test intentionally fails to verify CI logging")
    func intentionallyFailingTest() {
        // This test intentionally fails to verify that the CI pipeline
        // correctly extracts and displays test failure information.
        let expected = "CI failure logging works"
        let actual = "This will not match"

        #expect(expected == actual, "Intentional failure: Verifying CI failure logging enhancement")
    }

    @Test("Another intentional failure with different message")
    func anotherIntentionalFailure() {
        // Second failing test to verify multiple failures are captured
        #expect(1 == 2, "Intentional failure: Testing multiple failure extraction")
    }
}
