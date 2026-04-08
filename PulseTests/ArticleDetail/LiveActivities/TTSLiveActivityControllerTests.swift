import Foundation
@testable import Pulse
import Testing

@Suite("TTSLiveActivityController Tests")
@MainActor
struct TTSLiveActivityControllerTests {
    // MARK: - Initial state

    @Test("Controller is not active by default")
    func notActiveInitially() {
        let controller = TTSLiveActivityController.shared
        // Reset any state from prior tests so this assertion is deterministic.
        controller.end()
        #expect(controller.isActive == false)
    }

    // MARK: - Start safety

    @Test("start does not crash when ActivityKit is unavailable")
    func startIsSafeWhenUnavailable() {
        let controller = TTSLiveActivityController.shared
        controller.end()

        // In CI / simulator, Live Activities are typically not enabled.
        // The call must complete without throwing or crashing.
        controller.start(
            articleTitle: "Test article",
            sourceName: "Test source",
            speedLabel: "1x"
        )

        // Whether or not the activity actually started depends on the
        // simulator's ActivityKit support; we only assert that calling
        // `start` is safe and (when unavailable) leaves the controller
        // in the same state.
        controller.end()
        #expect(controller.isActive == false)
    }

    // MARK: - End idempotency

    @Test("end is a no-op when no activity exists")
    func endIsNoOp() {
        let controller = TTSLiveActivityController.shared
        controller.end()

        // Call end repeatedly — it should never crash and isActive must stay false.
        controller.end()
        controller.end()

        #expect(controller.isActive == false)
    }

    // MARK: - update safety

    @Test("update is a no-op when no activity is running")
    func updateIsNoOpWhenInactive() async {
        let controller = TTSLiveActivityController.shared
        controller.end()

        await controller.update(isPlaying: true, progress: 0.5, speedLabel: "1x")
        await controller.update(isPlaying: false, progress: 1.0, speedLabel: "2x")

        #expect(controller.isActive == false)
    }
}

// MARK: - TTSActivityAttributes Tests

@Suite("TTSActivityAttributes Tests")
struct TTSActivityAttributesTests {
    @Test("ContentState round-trips through JSON")
    func contentStateCodableRoundTrip() throws {
        let original = TTSActivityAttributes.ContentState(
            isPlaying: true,
            progress: 0.42,
            speedLabel: "1.25x"
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(TTSActivityAttributes.ContentState.self, from: data)

        #expect(decoded == original)
        #expect(decoded.isPlaying == true)
        #expect(decoded.progress == 0.42)
        #expect(decoded.speedLabel == "1.25x")
    }

    @Test("Attributes round-trip through JSON")
    func attributesCodableRoundTrip() throws {
        let original = TTSActivityAttributes(
            articleTitle: "SwiftUI 6.0 Brings Revolutionary New Features",
            sourceName: "TechCrunch"
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(TTSActivityAttributes.self, from: data)

        #expect(decoded.articleTitle == original.articleTitle)
        #expect(decoded.sourceName == original.sourceName)
    }

    @Test("ContentState equality is value-based")
    func contentStateEquality() {
        let stateA = TTSActivityAttributes.ContentState(
            isPlaying: true,
            progress: 0.35,
            speedLabel: "1x"
        )
        let stateB = TTSActivityAttributes.ContentState(
            isPlaying: true,
            progress: 0.35,
            speedLabel: "1x"
        )
        let stateC = TTSActivityAttributes.ContentState(
            isPlaying: false,
            progress: 0.35,
            speedLabel: "1x"
        )
        let stateD = TTSActivityAttributes.ContentState(
            isPlaying: true,
            progress: 0.36,
            speedLabel: "1x"
        )
        let stateE = TTSActivityAttributes.ContentState(
            isPlaying: true,
            progress: 0.35,
            speedLabel: "2x"
        )

        #expect(stateA == stateB)
        #expect(stateA != stateC)
        #expect(stateA != stateD)
        #expect(stateA != stateE)
    }

    @Test("ContentState is Hashable and produces consistent hashes")
    func contentStateHashable() {
        let stateA = TTSActivityAttributes.ContentState(
            isPlaying: true,
            progress: 0.5,
            speedLabel: "1.5x"
        )
        let stateB = TTSActivityAttributes.ContentState(
            isPlaying: true,
            progress: 0.5,
            speedLabel: "1.5x"
        )

        var hasherA = Hasher()
        var hasherB = Hasher()
        stateA.hash(into: &hasherA)
        stateB.hash(into: &hasherB)
        #expect(hasherA.finalize() == hasherB.finalize())
    }
}
