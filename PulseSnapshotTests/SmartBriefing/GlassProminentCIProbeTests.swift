import EntropyCore
@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

/// Temporary CI probe — NOT a permanent test. Determines whether the
/// `.buttonStyle(.glassProminent)`-blanks-the-whole-snapshot behavior
/// observed locally on Xcode 27.0 also reproduces on CI's pinned
/// Xcode 26.5.0 (`macos-26` runner). If the recorded image here shows
/// real content (not blank), the limitation documented in AGENTS.md
/// rule 37 is Xcode-27-specific and `SmartBriefingCardViewSnapshotTests`
/// should be restored. Delete this file once that's resolved either way.
@MainActor
final class GlassProminentCIProbeTests: XCTestCase {
    func testGlassProminentButtonRendersContent() {
        let view = VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Your commute, curated")
                .font(Typography.bodyMedium)
                .foregroundStyle(.secondary)

            Button {} label: {
                Label("Build My Briefing", systemImage: "headphones")
                    .font(Typography.labelLarge)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
        }
        .padding(Spacing.md)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .frame(width: 393)
        .background(Color.red)
        let controller = UIHostingController(rootView: view)
        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: SnapshotConfig.iPhoneAir),
            record: true
        )
    }
}
