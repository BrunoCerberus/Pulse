@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class SettingsPremiumSectionSnapshotTests: XCTestCase {
    private let iPhoneAirConfig = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 393, height: 852),
        traits: UITraitCollection(userInterfaceStyle: .dark)
    )

    func testSettingsPremiumSectionNotPremium() {
        let view = SettingsPremiumSection(
            isPremium: false,
            onUpgradeTapped: {}
        )

        assertSnapshot(matching: view, as: .image(layout: .device(config: iPhoneAirConfig)))
    }

    func testSettingsPremiumSectionIsPremium() {
        let view = SettingsPremiumSection(
            isPremium: true,
            onUpgradeTapped: {}
        )

        assertSnapshot(matching: view, as: .image(layout: .device(config: iPhoneAirConfig)))
    }
}
