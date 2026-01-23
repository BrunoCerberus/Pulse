import XCTest

/// Temporary UI test file to verify CI failure logging works correctly.
/// DELETE THIS FILE after verifying the CI enhancement.
final class CIVerificationUITests: BaseUITestCase {

    /// This test intentionally fails to verify CI logging
    func testIntentionalUIFailure() throws {
        // This test intentionally fails to verify that the CI pipeline
        // correctly extracts and displays UI test failure information.
        let nonExistentElement = app.buttons["ThisButtonDoesNotExist_CIVerification"]

        XCTAssertTrue(
            nonExistentElement.waitForExistence(timeout: 2),
            "Intentional UI test failure: Verifying CI failure logging enhancement"
        )
    }

    /// Another intentional UI test failure
    func testAnotherIntentionalUIFailure() throws {
        // Second failing UI test to verify multiple failures are captured
        XCTAssertEqual(
            app.windows.count,
            999,
            "Intentional UI test failure: Testing multiple UI failure extraction"
        )
    }
}
