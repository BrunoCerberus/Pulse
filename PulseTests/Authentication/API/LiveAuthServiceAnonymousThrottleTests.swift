import Foundation
@testable import Pulse
import Testing

@Suite("LiveAuthService Anonymous Throttle Tests", .serialized)
struct LiveAuthServiceAnonymousThrottleTests {
    private let suiteName = "com.pulse.anon.throttle.tests"

    private func freshDefaults() -> UserDefaults {
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    @Test("isAnonymousSignInThrottled returns false on a fresh device")
    func freshDeviceNotThrottled() {
        let defaults = freshDefaults()
        let throttled = LiveAuthService.isAnonymousSignInThrottled(
            now: 1000,
            defaults: defaults,
            throttleSeconds: 60
        )
        #expect(throttled == false)
    }

    @Test("isAnonymousSignInThrottled returns true within the window")
    func throttledWithinWindow() {
        let defaults = freshDefaults()
        defaults.set(1000.0, forKey: LiveAuthService.anonymousSignInLastAttemptKey)

        let throttled = LiveAuthService.isAnonymousSignInThrottled(
            now: 1030,
            defaults: defaults,
            throttleSeconds: 60
        )
        #expect(throttled == true)
    }

    @Test("isAnonymousSignInThrottled returns false after the window")
    func notThrottledAfterWindow() {
        let defaults = freshDefaults()
        defaults.set(1000.0, forKey: LiveAuthService.anonymousSignInLastAttemptKey)

        let throttled = LiveAuthService.isAnonymousSignInThrottled(
            now: 1061, // 61s later, throttle is 60s
            defaults: defaults,
            throttleSeconds: 60
        )
        #expect(throttled == false)
    }

    @Test("isAnonymousSignInThrottled does NOT update the timestamp")
    func readDoesNotMutate() {
        let defaults = freshDefaults()
        defaults.set(1000.0, forKey: LiveAuthService.anonymousSignInLastAttemptKey)

        _ = LiveAuthService.isAnonymousSignInThrottled(
            now: 1500,
            defaults: defaults,
            throttleSeconds: 60
        )
        // Confirms the throttle check is a pure read — a transient Firebase
        // failure in the caller won't burn the reviewer's window.
        #expect(defaults.double(forKey: LiveAuthService.anonymousSignInLastAttemptKey) == 1000)
    }

    @Test("recordAnonymousSignInAttempt writes the timestamp")
    func recordWritesTimestamp() {
        let defaults = freshDefaults()
        LiveAuthService.recordAnonymousSignInAttempt(
            at: 2000,
            defaults: defaults
        )
        #expect(defaults.double(forKey: LiveAuthService.anonymousSignInLastAttemptKey) == 2000)
    }

    @Test("Record followed by check inside the window throttles")
    func recordThenCheckRoundTrip() {
        let defaults = freshDefaults()
        LiveAuthService.recordAnonymousSignInAttempt(
            at: 1000,
            defaults: defaults
        )
        let throttled = LiveAuthService.isAnonymousSignInThrottled(
            now: 1030,
            defaults: defaults,
            throttleSeconds: 60
        )
        #expect(throttled == true)
    }
}
