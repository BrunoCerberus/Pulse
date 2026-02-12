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
        @State var newSource = ""
        @State var newKeyword = ""

        let view = SettingsMutedContentSection(
            mutedSources: [],
            mutedKeywords: [],
            newMutedSource: $newSource,
            newMutedKeyword: $newKeyword,
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
        @State var newSource = ""
        @State var newKeyword = ""

        let view = SettingsMutedContentSection(
            mutedSources: [],
            mutedKeywords: [],
            newMutedSource: $newSource,
            newMutedKeyword: $newKeyword,
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
        @State var newSource = ""
        @State var newKeyword = ""

        let view = SettingsMutedContentSection(
            mutedSources: ["TechCrunch", "BuzzFeed", "The Daily Mail"],
            mutedKeywords: ["politics", "celebrity gossip", "sports"],
            newMutedSource: $newSource,
            newMutedKeyword: $newKeyword,
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
        @State var newSource = "New Source"
        @State var newKeyword = "Breaking"

        let view = SettingsMutedContentSection(
            mutedSources: ["TechCrunch"],
            mutedKeywords: ["politics"],
            newMutedSource: $newSource,
            newMutedKeyword: $newKeyword,
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
