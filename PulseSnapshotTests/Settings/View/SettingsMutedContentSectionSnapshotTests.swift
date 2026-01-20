@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class SettingsMutedContentSectionSnapshotTests: XCTestCase {
    // MARK: - Empty Muted Content Tests

    func testMutedContentSectionEmpty() {
        let view = SettingsMutedContentSection(
            mutedSources: [],
            mutedKeywords: [],
            onAddSource: {},
            onRemoveSource: { _ in },
            onAddKeyword: {},
            onRemoveKeyword: { _ in },
            onClearHistory: {}
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

    // MARK: - With Muted Sources Tests

    func testMutedContentSectionWithSources() {
        let view = SettingsMutedContentSection(
            mutedSources: ["Daily Mail", "The Sun"],
            mutedKeywords: [],
            onAddSource: {},
            onRemoveSource: { _ in },
            onAddKeyword: {},
            onRemoveKeyword: { _ in },
            onClearHistory: {}
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

    // MARK: - With Muted Keywords Tests

    func testMutedContentSectionWithKeywords() {
        let view = SettingsMutedContentSection(
            mutedSources: [],
            mutedKeywords: ["celebrity", "politics", "scandal"],
            onAddSource: {},
            onRemoveSource: { _ in },
            onAddKeyword: {},
            onRemoveKeyword: { _ in },
            onClearHistory: {}
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

    // MARK: - With Both Sources and Keywords Tests

    func testMutedContentSectionWithBoth() {
        let view = SettingsMutedContentSection(
            mutedSources: ["Daily Mail", "The Sun", "TMZ"],
            mutedKeywords: ["celebrity", "politics", "scandal", "gossip"],
            onAddSource: {},
            onRemoveSource: { _ in },
            onAddKeyword: {},
            onRemoveKeyword: { _ in },
            onClearHistory: {}
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

    // MARK: - With Many Items Tests

    func testMutedContentSectionWithManyItems() {
        let sources = ["Source 1", "Source 2", "Source 3", "Source 4", "Source 5"]
        let keywords = ["keyword1", "keyword2", "keyword3", "keyword4", "keyword5", "keyword6"]

        let view = SettingsMutedContentSection(
            mutedSources: sources,
            mutedKeywords: keywords,
            onAddSource: {},
            onRemoveSource: { _ in },
            onAddKeyword: {},
            onRemoveKeyword: { _ in },
            onClearHistory: {}
        )
        .frame(width: 375, height: 600)
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

    func testMutedContentSectionDarkMode() {
        let view = SettingsMutedContentSection(
            mutedSources: ["Daily Mail", "The Sun"],
            mutedKeywords: ["celebrity", "politics"],
            onAddSource: {},
            onRemoveSource: { _ in },
            onAddKeyword: {},
            onRemoveKeyword: { _ in },
            onClearHistory: {}
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

    func testMutedContentSectionLightMode() {
        let view = SettingsMutedContentSection(
            mutedSources: ["Daily Mail", "The Sun"],
            mutedKeywords: ["celebrity", "politics"],
            onAddSource: {},
            onRemoveSource: { _ in },
            onAddKeyword: {},
            onRemoveKeyword: { _ in },
            onClearHistory: {}
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

    // MARK: - Long Content Tests

    func testMutedContentSectionWithLongSourceNames() {
        let view = SettingsMutedContentSection(
            mutedSources: ["Very Long Source Name That Might Wrap", "Another Really Long Source Name"],
            mutedKeywords: [],
            onAddSource: {},
            onRemoveSource: { _ in },
            onAddKeyword: {},
            onRemoveKeyword: { _ in },
            onClearHistory: {}
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
}
