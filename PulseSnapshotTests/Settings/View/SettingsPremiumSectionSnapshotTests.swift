@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class SettingsPremiumSectionSnapshotTests: XCTestCase {
    // MARK: - Premium Inactive Tests

    func testPremiumSectionNotPremium() {
        let view = SettingsPremiumSection(
            isPremium: false,
            onUpgrade: {},
            onRestore: {}
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

    // MARK: - Premium Active Tests

    func testPremiumSectionWithPremium() {
        let view = SettingsPremiumSection(
            isPremium: true,
            onUpgrade: {},
            onRestore: {}
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

    func testPremiumSectionNotPremiumDarkMode() {
        let view = SettingsPremiumSection(
            isPremium: false,
            onUpgrade: {},
            onRestore: {}
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

    func testPremiumSectionWithPremiumDarkMode() {
        let view = SettingsPremiumSection(
            isPremium: true,
            onUpgrade: {},
            onRestore: {}
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

    func testPremiumSectionNotPremiumLightMode() {
        let view = SettingsPremiumSection(
            isPremium: false,
            onUpgrade: {},
            onRestore: {}
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

    func testPremiumSectionWithPremiumLightMode() {
        let view = SettingsPremiumSection(
            isPremium: true,
            onUpgrade: {},
            onRestore: {}
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

    func testPremiumSectionInSettingsContext() {
        let view = ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SettingsPremiumSection(
                    isPremium: false,
                    onUpgrade: {},
                    onRestore: {}
                )

                Divider()

                SettingsPremiumSection(
                    isPremium: true,
                    onUpgrade: {},
                    onRestore: {}
                )
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
