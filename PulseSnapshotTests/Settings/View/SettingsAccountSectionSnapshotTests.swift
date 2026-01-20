@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class SettingsAccountSectionSnapshotTests: XCTestCase {
    // MARK: - Signed In State Tests

    func testAccountSectionSignedIn() {
        let view = SettingsAccountSection(
            userEmail: "user@example.com",
            onSignOut: {}
        )
        .frame(width: 375)
        .padding()
        .background(Color(.systemBackground))

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    func testAccountSectionWithLongEmail() {
        let view = SettingsAccountSection(
            userEmail: "very.long.email.address.with.many.characters@example.com",
            onSignOut: {}
        )
        .frame(width: 375)
        .padding()
        .background(Color(.systemBackground))

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    func testAccountSectionWithSimpleEmail() {
        let view = SettingsAccountSection(
            userEmail: "test@gmail.com",
            onSignOut: {}
        )
        .frame(width: 375)
        .padding()
        .background(Color(.systemBackground))

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    // MARK: - Dark Mode Tests

    func testAccountSectionDarkMode() {
        let view = SettingsAccountSection(
            userEmail: "user@example.com",
            onSignOut: {}
        )
        .frame(width: 375)
        .padding()
        .background(Color(.systemBackground))
        .preferredColorScheme(.dark)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    func testAccountSectionLightMode() {
        let view = SettingsAccountSection(
            userEmail: "user@example.com",
            onSignOut: {}
        )
        .frame(width: 375)
        .padding()
        .background(Color(.systemBackground))
        .preferredColorScheme(.light)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    // MARK: - Context Tests

    func testAccountSectionInScrollView() {
        let view = ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SettingsAccountSection(
                    userEmail: "user@example.com",
                    onSignOut: {}
                )

                Divider()

                Text("Other Settings")
                    .font(Typography.titleMedium)
            }
            .padding()
        }
        .frame(width: 375, height: 600)
        .background(Color(.systemBackground))

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }
}
