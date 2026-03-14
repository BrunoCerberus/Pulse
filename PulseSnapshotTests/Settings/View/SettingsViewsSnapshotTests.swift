import EntropyCore
@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class SettingsViewsSnapshotTests: XCTestCase {
    private let iPhoneAirConfig = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 393, height: 852),
        traits: UITraitCollection(userInterfaceStyle: .dark)
    )

    private let iPhoneAirLightConfig = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 393, height: 852),
        traits: UITraitCollection(userInterfaceStyle: .light)
    )

    // MARK: - SettingsPremiumSection Tests

    func testSettingsPremiumSectionNotPremium() {
        let view = SettingsPremiumSection(
            isPremium: false,
            onUpgradeTapped: {}
        )

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: iPhoneAirConfig),
            record: false
        )
    }

    func testSettingsPremiumSectionLightMode() {
        let view = SettingsPremiumSection(
            isPremium: false,
            onUpgradeTapped: {}
        )

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: iPhoneAirLightConfig),
            record: false
        )
    }

    func testSettingsPremiumSectionIsPremium() {
        let view = SettingsPremiumSection(
            isPremium: true,
            onUpgradeTapped: {}
        )

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: iPhoneAirConfig),
            record: false
        )
    }

    // MARK: - SettingsMutedContentSection Tests

    func testSettingsMutedContentSectionEmpty() {
        let view = SettingsMutedContentSection(
            mutedSources: [],
            mutedKeywords: [],
            newMutedSource: .constant(""),
            newMutedKeyword: .constant(""),
            onAddMutedSource: {},
            onRemoveMutedSource: { _ in },
            onAddMutedKeyword: {},
            onRemoveMutedKeyword: { _ in }
        )

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: iPhoneAirConfig),
            record: false
        )
    }

    func testSettingsMutedContentSectionLightMode() {
        let view = SettingsMutedContentSection(
            mutedSources: [],
            mutedKeywords: [],
            newMutedSource: .constant(""),
            newMutedKeyword: .constant(""),
            onAddMutedSource: {},
            onRemoveMutedSource: { _ in },
            onAddMutedKeyword: {},
            onRemoveMutedKeyword: { _ in }
        )

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: iPhoneAirLightConfig),
            record: false
        )
    }

    func testSettingsMutedContentSectionWithData() {
        let view = SettingsMutedContentSection(
            mutedSources: ["TechCrunch", "BuzzFeed", "The Daily Mail"],
            mutedKeywords: ["politics", "celebrity gossip", "sports"],
            newMutedSource: .constant(""),
            newMutedKeyword: .constant(""),
            onAddMutedSource: {},
            onRemoveMutedSource: { _ in },
            onAddMutedKeyword: {},
            onRemoveMutedKeyword: { _ in }
        )

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: iPhoneAirConfig),
            record: false
        )
    }

    func testSettingsMutedContentSectionWithInput() {
        let view = SettingsMutedContentSection(
            mutedSources: ["TechCrunch"],
            mutedKeywords: ["politics"],
            newMutedSource: .constant("New Source"),
            newMutedKeyword: .constant("Breaking"),
            onAddMutedSource: {},
            onRemoveMutedSource: { _ in },
            onAddMutedKeyword: {},
            onRemoveMutedKeyword: { _ in }
        )

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: iPhoneAirConfig),
            record: false
        )
    }
}
