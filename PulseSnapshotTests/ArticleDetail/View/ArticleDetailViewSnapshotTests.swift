import EntropyCore
@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class ArticleDetailViewSnapshotTests: XCTestCase {
    private var serviceLocator: ServiceLocator!

    // Custom device config matching CI's iPhone Air simulator
    private let iPhoneAirConfig = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 393, height: 852),
        traits: UITraitCollection(userInterfaceStyle: .dark)
    )

    override func setUp() {
        super.setUp()
        serviceLocator = ServiceLocator()
        serviceLocator.register(StorageService.self, instance: MockStorageService())
    }

    // Fixed date for snapshot stability (Jan 1, 2023 - will always show "2 yr ago" or similar)
    private var snapshotArticle: Article {
        Article(
            id: "snapshot-1",
            title: "SwiftUI 6.0 Brings Revolutionary New Features",
            description: "Apple announces major updates to SwiftUI at WWDC 2024",
            content: "Full article content here...",
            author: "John Appleseed",
            source: ArticleSource(id: "techcrunch", name: "TechCrunch"),
            url: "https://example.com/1",
            imageURL: nil,
            publishedAt: Date(timeIntervalSince1970: 1_672_531_200), // Jan 1, 2023 00:00:00 UTC
            category: .technology
        )
    }

    func testArticleDetailView() {
        let view = NavigationStack {
            ArticleDetailView(article: snapshotArticle, serviceLocator: serviceLocator)
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }
}
