import Foundation
@testable import Pulse
import SwiftUI
import Testing
import UIKit

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
            onStartFreshTapped: {},
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
                statusMessage: nil,
            ),
            onBuildBriefingTapped: {},
            onStartFreshTapped: {},
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
                statusMessage: nil,
            ),
            onBuildBriefingTapped: {},
            onStartFreshTapped: {},
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
                statusMessage: "Queued 12 articles",
            ),
            onBuildBriefingTapped: {},
            onStartFreshTapped: {},
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
                statusMessage: nil,
            ),
            onBuildBriefingTapped: { buildTapped = true },
            onStartFreshTapped: { startFreshTapped = true },
        )
        view.onBuildBriefingTapped()
        view.onStartFreshTapped()

        #expect(buildTapped)
        #expect(startFreshTapped)
    }

    /// `@Environment(\.dynamicTypeSize)` only resolves to a non-default value
    /// under a real render pass, so `_ = view.body` can't exercise the
    /// accessibility-size branch — this forces one via `UIHostingController`
    /// (mirrors `PatchCoverageRenderingTests.render`), asserting only that
    /// layout completes without crashing, not pixel content.
    @Test("Buttons stack vertically instead of truncating at an accessibility Dynamic Type size")
    func buttonsStackVerticallyAtAccessibilitySize() {
        let view = SmartBriefingCardView(
            viewState: SmartBriefingViewState(
                isVisible: true,
                isBuilding: false,
                lastServedAt: .now,
                statusMessage: nil,
            ),
            onBuildBriefingTapped: {},
            onStartFreshTapped: {},
        )
        Self.render(view.environment(\.dynamicTypeSize, .accessibility3))
    }

    private static func render(_ view: some View, size: CGSize = CGSize(width: 393, height: 300)) {
        guard let windowScene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first else {
            Issue.record("Expected an active window scene for rendering")
            return
        }

        let window = UIWindow(windowScene: windowScene)
        window.frame = CGRect(origin: .zero, size: size)
        let controller = UIHostingController(rootView: view)
        controller.view.frame = CGRect(origin: .zero, size: size)

        window.rootViewController = controller
        window.makeKeyAndVisible()
        window.setNeedsLayout()
        window.layoutIfNeeded()
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        withExtendedLifetime(window) {
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
    }
}
