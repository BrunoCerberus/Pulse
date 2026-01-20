@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class ShareSheetSnapshotTests: XCTestCase {
    // MARK: - Helper Method

    private func createMockArticle(
        title: String = "Test Article",
        url: String = "https://example.com/article"
    ) -> Article {
        Article(
            id: "test-article",
            title: title,
            description: "Test article description",
            imageUrl: nil,
            publishedAt: Date(),
            url: url,
            source: "The Guardian",
            category: .world,
            content: nil
        )
    }

    // MARK: - Basic Share Sheet Tests

    func testShareSheetStandard() {
        let article = createMockArticle(
            title: "Interesting Article to Share",
            url: "https://theguardian.com/world/2024/01/15/article-title"
        )

        let view = ShareSheet(article: article, isPresented: .constant(true))
            .frame(height: 400)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    // MARK: - Different Article Tests

    func testShareSheetWithLongTitle() {
        let article = createMockArticle(
            title: "This Is A Very Long Article Title That Might Wrap Across Multiple Lines In The Share Sheet",
            url: "https://theguardian.com/world/2024/01/15/article-title"
        )

        let view = ShareSheet(article: article, isPresented: .constant(true))
            .frame(height: 400)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    func testShareSheetWithShortTitle() {
        let article = createMockArticle(
            title: "News",
            url: "https://theguardian.com/article"
        )

        let view = ShareSheet(article: article, isPresented: .constant(true))
            .frame(height: 400)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    // MARK: - Dark Mode Tests

    func testShareSheetDarkMode() {
        let article = createMockArticle(
            title: "Article for Sharing in Dark Mode",
            url: "https://theguardian.com/article"
        )

        let view = ShareSheet(article: article, isPresented: .constant(true))
            .frame(height: 400)
            .preferredColorScheme(.dark)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    func testShareSheetLightMode() {
        let article = createMockArticle(
            title: "Article for Sharing in Light Mode",
            url: "https://theguardian.com/article"
        )

        let view = ShareSheet(article: article, isPresented: .constant(true))
            .frame(height: 400)
            .preferredColorScheme(.light)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    // MARK: - Accessibility Tests

    func testShareSheetAccessibility() {
        let article = createMockArticle()

        let view = ShareSheet(article: article, isPresented: .constant(true))
            .frame(height: 400)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }
}
