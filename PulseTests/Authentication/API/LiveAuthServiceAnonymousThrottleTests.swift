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

    @Test("Allows the first attempt and records the timestamp")
    func firstAttemptAllowed() {
        let defaults = freshDefaults()
        let now: TimeInterval = 1000

        let result = LiveAuthService.checkAnonymousSignInThrottle(
            now: now,
            defaults: defaults,
            throttleSeconds: 60
        )

        if case .failure = result {
            Issue.record("First attempt should not be throttled")
        }
        #expect(defaults.double(forKey: LiveAuthService.anonymousSignInLastAttemptKey) == now)
    }

    @Test("Blocks a second attempt within the throttle window")
    func secondAttemptThrottled() {
        let defaults = freshDefaults()
        defaults.set(1000.0, forKey: LiveAuthService.anonymousSignInLastAttemptKey)

        let result = LiveAuthService.checkAnonymousSignInThrottle(
            now: 1030,
            defaults: defaults,
            throttleSeconds: 60
        )

        guard case let .failure(error) = result else {
            Issue.record("Expected throttle to reject the second attempt")
            return
        }
        if case let .unknown(message) = error {
            #expect(message.contains("throttled"))
        } else {
            Issue.record("Unexpected error type")
        }
        // Timestamp must NOT be updated on a throttled attempt.
        #expect(defaults.double(forKey: LiveAuthService.anonymousSignInLastAttemptKey) == 1000)
    }

    @Test("Allows another attempt after the throttle window elapses")
    func secondAttemptAllowedAfterWindow() {
        let defaults = freshDefaults()
        defaults.set(1000.0, forKey: LiveAuthService.anonymousSignInLastAttemptKey)

        let result = LiveAuthService.checkAnonymousSignInThrottle(
            now: 1061, // 61s later, throttle is 60s
            defaults: defaults,
            throttleSeconds: 60
        )

        if case .failure = result {
            Issue.record("Throttle window should have elapsed")
        }
        #expect(defaults.double(forKey: LiveAuthService.anonymousSignInLastAttemptKey) == 1061)
    }
}
