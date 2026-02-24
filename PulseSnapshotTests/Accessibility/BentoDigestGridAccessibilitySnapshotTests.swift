import EntropyCore
@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

/// Snapshot tests verifying BentoDigestGrid layout at accessibility text sizes.
/// Validates the VStack transition for stats and topics sections at accessibility sizes.
@MainActor
final class BentoDigestGridAccessibilitySnapshotTests: XCTestCase {
    private var snapshotDigest: DigestViewItem {
        DigestViewItem(
            from: DailyDigest(
                id: "a11y-digest",
                summary: "**Tech** Apple announces new M4 chips. **Business** Markets rally on strong earnings. **Health** New study on sleep quality.",
                sourceArticles: Article.mockArticles,
                generatedAt: Date(timeIntervalSince1970: 1_672_531_200)
            )
        )
    }

    private var snapshotSourceArticles: [FeedSourceArticle] {
        Article.mockArticles.map { FeedSourceArticle(from: $0) }
    }

    func testBentoDigestGridAccessibilitySize() {
        let view = ScrollView {
            BentoDigestGrid(
                digest: snapshotDigest,
                sourceArticles: snapshotSourceArticles,
                onArticleTapped: { _ in }
            )
        }
        .frame(width: 375)
        .padding()
        .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: SnapshotConfig.iPhoneAirAccessibility),
            record: true
        )
    }

    func testBentoDigestGridExtraExtraLargeSize() {
        let view = ScrollView {
            BentoDigestGrid(
                digest: snapshotDigest,
                sourceArticles: snapshotSourceArticles,
                onArticleTapped: { _ in }
            )
        }
        .frame(width: 375)
        .padding()
        .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: SnapshotConfig.iPhoneAirExtraExtraLarge),
            record: true
        )
    }
}
