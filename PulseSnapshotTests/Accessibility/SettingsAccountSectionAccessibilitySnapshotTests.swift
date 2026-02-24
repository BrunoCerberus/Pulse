import EntropyCore
@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

/// Snapshot tests verifying SettingsAccountSection layout at accessibility text sizes.
/// Validates the HStack-to-VStack transition for profile info at accessibility sizes.
@MainActor
final class SettingsAccountSectionAccessibilitySnapshotTests: XCTestCase {
    func testSettingsAccountSectionAccessibilitySize() {
        let view = List {
            SettingsAccountSection(
                currentUser: AuthUser.mock,
                onSignOutTapped: {}
            )
        }
        .frame(width: 375)
        .padding()
        .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: SnapshotConfig.iPhoneAirAccessibility),
            record: true
        )
    }

    func testSettingsAccountSectionExtraExtraLargeSize() {
        let view = List {
            SettingsAccountSection(
                currentUser: AuthUser.mock,
                onSignOutTapped: {}
            )
        }
        .frame(width: 375)
        .padding()
        .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: SnapshotConfig.iPhoneAirExtraExtraLarge),
            record: true
        )
    }
}
