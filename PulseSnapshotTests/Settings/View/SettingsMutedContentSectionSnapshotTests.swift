@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class SettingsMutedContentSectionSnapshotTests: XCTestCase {
    @State private var newSource = ""
    @State private var newKeyword = ""

    private let iPhoneAirConfig = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 393, height: 852),
        traits: UITraitCollection(userInterfaceStyle: .dark)
    )

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

        assertSnapshot(matching: view, as: .image(layout: .device(config: iPhoneAirConfig)))
    }

    func testSettingsMutedContentSectionWithData() {
        let view = SettingsMutedContentSection(
            mutedSources: ["Source1", "Source2", "Source3"],
            mutedKeywords: ["keyword1", "keyword2"],
            newMutedSource: .constant(""),
            newMutedKeyword: .constant(""),
            onAddMutedSource: {},
            onRemoveMutedSource: { _ in },
            onAddMutedKeyword: {},
            onRemoveMutedKeyword: { _ in }
        )

        assertSnapshot(matching: view, as: .image(layout: .device(config: iPhoneAirConfig)))
    }

    func testSettingsMutedContentSectionLongItems() {
        let view = SettingsMutedContentSection(
            mutedSources: ["Very Long Source Name That Tests Truncation", "Another Long Source"],
            mutedKeywords: ["extended keyword", "another lengthy keyword phrase"],
            newMutedSource: .constant(""),
            newMutedKeyword: .constant(""),
            onAddMutedSource: {},
            onRemoveMutedSource: { _ in },
            onAddMutedKeyword: {},
            onRemoveMutedKeyword: { _ in }
        )

        assertSnapshot(matching: view, as: .image(layout: .device(config: iPhoneAirConfig)))
    }
}
