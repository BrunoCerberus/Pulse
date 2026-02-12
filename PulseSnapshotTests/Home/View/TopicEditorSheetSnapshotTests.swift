import EntropyCore
@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class TopicEditorSheetSnapshotTests: XCTestCase {
    private let iPhoneAirConfig = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 393, height: 600),
        traits: UITraitCollection(userInterfaceStyle: .dark)
    )

    private let iPhoneAirLightConfig = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 393, height: 600),
        traits: UITraitCollection(userInterfaceStyle: .light)
    )

    // MARK: - TopicEditorSheet Tests

    func testTopicEditorSheetWithSelections() {
        let view = TopicEditorSheet(
            allTopics: NewsCategory.allCases,
            followedTopics: [.technology, .science, .business],
            onToggleTopic: { _ in },
            onDismiss: {}
        )

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: iPhoneAirConfig),
            record: false
        )
    }

    func testTopicEditorSheetLightMode() {
        let view = TopicEditorSheet(
            allTopics: NewsCategory.allCases,
            followedTopics: [.technology, .science, .business],
            onToggleTopic: { _ in },
            onDismiss: {}
        )

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: iPhoneAirLightConfig),
            record: false
        )
    }

    func testTopicEditorSheetEmpty() {
        let view = TopicEditorSheet(
            allTopics: NewsCategory.allCases,
            followedTopics: [],
            onToggleTopic: { _ in },
            onDismiss: {}
        )

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: iPhoneAirConfig),
            record: false
        )
    }

    func testTopicEditorSheetAllSelected() {
        let view = TopicEditorSheet(
            allTopics: NewsCategory.allCases,
            followedTopics: NewsCategory.allCases,
            onToggleTopic: { _ in },
            onDismiss: {}
        )

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: iPhoneAirConfig),
            record: false
        )
    }

    func testTopicEditorSheetSingleSelection() {
        let view = TopicEditorSheet(
            allTopics: NewsCategory.allCases,
            followedTopics: [.technology],
            onToggleTopic: { _ in },
            onDismiss: {}
        )

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: iPhoneAirConfig),
            record: false
        )
    }
}
