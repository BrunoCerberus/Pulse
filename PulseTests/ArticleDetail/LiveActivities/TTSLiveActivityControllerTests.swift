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
            currentTitle: "Test article",
            currentSource: "Test source",
            speedLabel: "1x",
            queuePosition: "1/5"
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

        await controller.update(
            isPlaying: true,
            progress: 0.5,
            speedLabel: "1x",
            currentTitle: "Title",
            currentSource: "Source",
            queuePosition: nil
        )
        await controller.update(
            isPlaying: false,
            progress: 1.0,
            speedLabel: "2x",
            currentTitle: "Other title",
            currentSource: "Other source",
            queuePosition: "3/7"
        )

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
            speedLabel: "1.25x",
            currentTitle: "SwiftUI 6.0 Brings Revolutionary New Features",
            currentSource: "TechCrunch",
            queuePosition: "2/11"
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(TTSActivityAttributes.ContentState.self, from: data)

        #expect(decoded == original)
        #expect(decoded.isPlaying == true)
        #expect(decoded.progress == 0.42)
        #expect(decoded.speedLabel == "1.25x")
        #expect(decoded.currentTitle == "SwiftUI 6.0 Brings Revolutionary New Features")
        #expect(decoded.currentSource == "TechCrunch")
        #expect(decoded.queuePosition == "2/11")
    }

    @Test("ContentState with nil queue position round-trips through JSON")
    func contentStateNilQueuePositionRoundTrip() throws {
        let original = TTSActivityAttributes.ContentState(
            isPlaying: false,
            progress: 0.0,
            speedLabel: "1x",
            currentTitle: "Title",
            currentSource: "Source",
            queuePosition: nil
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(TTSActivityAttributes.ContentState.self, from: data)

        #expect(decoded == original)
        #expect(decoded.queuePosition == nil)
    }

    @Test("ContentState equality is value-based")
    func contentStateEquality() {
        func makeState(
            isPlaying: Bool = true,
            progress: Double = 0.35,
            speedLabel: String = "1x",
            currentTitle: String = "Title",
            queuePosition: String? = "2/11"
        ) -> TTSActivityAttributes.ContentState {
            TTSActivityAttributes.ContentState(
                isPlaying: isPlaying,
                progress: progress,
                speedLabel: speedLabel,
                currentTitle: currentTitle,
                currentSource: "Source",
                queuePosition: queuePosition
            )
        }

        #expect(makeState() == makeState())
        #expect(makeState() != makeState(isPlaying: false))
        #expect(makeState() != makeState(progress: 0.36))
        #expect(makeState() != makeState(speedLabel: "2x"))
        #expect(makeState() != makeState(currentTitle: "Other"))
        #expect(makeState() != makeState(queuePosition: nil))
    }

    @Test("ContentState is Hashable and produces consistent hashes")
    func contentStateHashable() {
        let stateA = TTSActivityAttributes.ContentState(
            isPlaying: true,
            progress: 0.5,
            speedLabel: "1.5x",
            currentTitle: "Title",
            currentSource: "Source",
            queuePosition: "4/9"
        )
        let stateB = TTSActivityAttributes.ContentState(
            isPlaying: true,
            progress: 0.5,
            speedLabel: "1.5x",
            currentTitle: "Title",
            currentSource: "Source",
            queuePosition: "4/9"
        )

        var hasherA = Hasher()
        var hasherB = Hasher()
        stateA.hash(into: &hasherA)
        stateB.hash(into: &hasherB)
        #expect(hasherA.finalize() == hasherB.finalize())
    }
}
