import EntropyCore
@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

/// Snapshot tests verifying MediaCard layout at accessibility text sizes.
/// Validates the HStack-to-VStack transition for media cards.
@MainActor
final class MediaCardAccessibilitySnapshotTests: XCTestCase {
    private var snapshotMediaItem: MediaViewItem {
        MediaViewItem(
            from: Article(
                id: "a11y-media-1",
                title: "iPhone 16 Pro Max Review: The Best iPhone Yet?",
                description: "A comprehensive look at Apple's latest flagship.",
                source: ArticleSource(id: "mkbhd", name: "MKBHD"),
                url: "https://youtube.com",
                imageURL: nil,
                publishedAt: Date(timeIntervalSince1970: 1_672_531_200),
                mediaType: .video,
                mediaURL: "https://youtube.com",
                mediaDuration: 1245
            )
        )
    }

    func testMediaCardAccessibilitySize() {
        let view = MediaCard(
            item: snapshotMediaItem,
            onTap: {},
            onPlay: {},
            onShare: {}
        )
        .frame(width: 375)
        .padding()
        .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: SnapshotConfig.iPhoneAirAccessibility),
            record: false
        )
    }

    func testMediaCardExtraExtraLargeSize() {
        let view = MediaCard(
            item: snapshotMediaItem,
            onTap: {},
            onPlay: {},
            onShare: {}
        )
        .frame(width: 375)
        .padding()
        .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: SnapshotConfig.iPhoneAirExtraExtraLarge),
            record: false
        )
    }
}
