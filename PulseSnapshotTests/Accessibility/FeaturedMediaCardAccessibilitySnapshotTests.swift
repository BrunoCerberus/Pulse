import EntropyCore
@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

/// Snapshot tests verifying FeaturedMediaCard layout at accessibility text sizes.
/// Validates the height and layout adaptation for accessibility Dynamic Type sizes.
@MainActor
// swiftlint:disable:next type_name
final class FeaturedMediaCardAccessibilitySnapshotTests: XCTestCase {
    private var snapshotMediaItem: MediaViewItem {
        MediaViewItem(
            from: Article(
                id: "a11y-featured-1",
                title: "iPhone 16 Pro Max Review: The Best iPhone Yet?",
                description: "A comprehensive look at Apple's latest flagship device.",
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

    func testFeaturedMediaCardAccessibilitySize() {
        // Pass explicit expanded width mirroring how MediaView wraps the card
        // at accessibility sizes (the card's previous UIApplication-based probe
        // was removed in favor of caller-driven sizing).
        let view = FeaturedMediaCard(
            item: snapshotMediaItem,
            cardWidth: 345,
            onTap: {}
        )
        .frame(width: 375)
        .padding()
        .background(Color(red: 0.1, green: 0.1, blue: 0.15))
        .drawingGroup()

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: SnapshotConfig.iPhoneAirAccessibility),
            record: false
        )
    }

    func testFeaturedMediaCardExtraExtraLargeSize() {
        let view = FeaturedMediaCard(
            item: snapshotMediaItem,
            onTap: {}
        )
        .frame(width: 375)
        .padding()
        .background(Color(red: 0.1, green: 0.1, blue: 0.15))
        .drawingGroup()

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: SnapshotConfig.iPhoneAirExtraExtraLarge),
            record: false
        )
    }
}
