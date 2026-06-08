import Foundation

/// Release-safe access to test-only launch-environment flags.
///
/// The app's UI- and unit-test harnesses set custom environment variables
/// (`UI_TESTING`, `IS_RUNNING_UNIT_TESTS`) to switch in mock services, skip the
/// splash / onboarding, and otherwise adjust behaviour for automation. Those
/// affordances must never be reachable in a shipped App Store build, so every
/// accessor here compiles to a constant `false` outside `DEBUG` — the env reads
/// don't even exist in the Release binary. Call sites use these accessors
/// instead of reading `ProcessInfo.processInfo.environment` directly so the
/// gating can't be forgotten.
enum TestEnvironment {
    /// True only in DEBUG when launched by the UI-test harness.
    static var isUITesting: Bool {
        #if DEBUG
            let env = ProcessInfo.processInfo.environment
            return env["UI_TESTING"] == "1" || env["XCTestConfigurationFilePath"] == "UI"
        #else
            return false
        #endif
    }

    /// True only in DEBUG when running under the unit-test harness.
    static var isRunningUnitTests: Bool {
        #if DEBUG
            return ProcessInfo.processInfo.environment["IS_RUNNING_UNIT_TESTS"] == "YES"
        #else
            return false
        #endif
    }

    /// True only in DEBUG when running under any test harness — unit or UI.
    /// Includes the system-set `XCTestConfigurationFilePath` (present whenever
    /// XCTest hosts the app) so test-only UI fallbacks can detect either mode.
    static var isRunningTests: Bool {
        #if DEBUG
            return isUITesting
                || isRunningUnitTests
                || ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        #else
            return false
        #endif
    }
}
