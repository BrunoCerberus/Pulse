import Foundation
@testable import Pulse
import Testing

/// Visual regression coverage for Liquid Glass materials can't be verified
/// via snapshot tests here (see `AGENTS.md` rule 37 — `.buttonStyle(.glassProminent)`
/// renders as a blank canvas under `UIHostingController` + `SnapshotTesting` on
/// this SDK). These tests instead verify the view body evaluates without
/// crashing across every state branch, mirroring `SplashScreenViewTests`.
@Suite("SmartBriefingCardView Tests")
@MainActor
struct SmartBriefingCardViewTests {
    @Test("Body evaluates for the fresh (never-served) state")
    func bodyEvaluatesFreshState() {
        let view = SmartBriefingCardView(
            viewState: .initial,
            onBuildBriefingTapped: {},
            onStartFreshTapped: {}
        )
        _ = view.body
    }

    @Test("Body evaluates for the recently-served state (shows the Start Fresh button)")
    func bodyEvaluatesRecentlyServedState() {
        let view = SmartBriefingCardView(
            viewState: SmartBriefingViewState(
                isVisible: true,
                isBuilding: false,
                lastServedAt: .now.addingTimeInterval(-3 * 3600),
                statusMessage: nil
            ),
            onBuildBriefingTapped: {},
            onStartFreshTapped: {}
        )
        _ = view.body
    }

    @Test("Body evaluates for the building state (ProgressView branch)")
    func bodyEvaluatesBuildingState() {
        let view = SmartBriefingCardView(
            viewState: SmartBriefingViewState(
                isVisible: true,
                isBuilding: true,
                lastServedAt: nil,
                statusMessage: nil
            ),
            onBuildBriefingTapped: {},
            onStartFreshTapped: {}
        )
        _ = view.body
    }

    @Test("Body evaluates with a transient status message set")
    func bodyEvaluatesWithStatusMessage() {
        let view = SmartBriefingCardView(
            viewState: SmartBriefingViewState(
                isVisible: true,
                isBuilding: false,
                lastServedAt: .now,
                statusMessage: "Queued 12 articles"
            ),
            onBuildBriefingTapped: {},
            onStartFreshTapped: {}
        )
        _ = view.body
    }

    @Test("Tap callbacks fire")
    func tapCallbacksFire() {
        var buildTapped = false
        var startFreshTapped = false
        let view = SmartBriefingCardView(
            viewState: SmartBriefingViewState(
                isVisible: true,
                isBuilding: false,
                lastServedAt: .now,
                statusMessage: nil
            ),
            onBuildBriefingTapped: { buildTapped = true },
            onStartFreshTapped: { startFreshTapped = true }
        )
        view.onBuildBriefingTapped()
        view.onStartFreshTapped()

        #expect(buildTapped)
        #expect(startFreshTapped)
    }
}
