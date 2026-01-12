import EntropyCore
@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class CollectionCardSnapshotTests: XCTestCase {
    // Custom device config for component testing (dark mode)
    private let componentConfig = ViewImageConfig(
        safeArea: .zero,
        size: CGSize(width: 220, height: 220),
        traits: UITraitCollection(userInterfaceStyle: .dark)
    )

    // Row config for user collection rows
    private let rowConfig = ViewImageConfig(
        safeArea: .zero,
        size: CGSize(width: 393, height: 100),
        traits: UITraitCollection(userInterfaceStyle: .dark)
    )

    // Fixed date for snapshot stability
    private let fixedDate = Date(timeIntervalSince1970: 1_672_531_200)

    // MARK: - Collection Card Tests

    func testCollectionCardDefault() {
        let item = CollectionViewItem(from: Collection(
            id: "test",
            name: "Climate Crisis",
            description: "Understand the science and solutions",
            imageURL: nil,
            articles: [],
            articleIDs: Set((1...10).map { "\($0)" }),
            readArticleIDs: ["1", "2", "3"],
            collectionType: .featured,
            isPremium: false,
            createdAt: fixedDate,
            updatedAt: fixedDate
        ))

        let view = CollectionCard(item: item) {}
            .padding()
            .background(LinearGradient.subtleBackground)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: componentConfig, precision: 0.99)),
            record: false
        )
    }

    func testCollectionCardPremium() {
        let item = CollectionViewItem(from: Collection(
            id: "test-premium",
            name: "AI & Technology",
            description: "Latest in artificial intelligence",
            imageURL: nil,
            articles: [],
            articleIDs: Set((1...8).map { "\($0)" }),
            readArticleIDs: [],
            collectionType: .featured,
            isPremium: true,
            createdAt: fixedDate,
            updatedAt: fixedDate
        ))

        let view = CollectionCard(item: item) {}
            .padding()
            .background(LinearGradient.subtleBackground)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: componentConfig, precision: 0.99)),
            record: false
        )
    }

    func testCollectionCardCompleted() {
        let item = CollectionViewItem(from: Collection(
            id: "test-completed",
            name: "Global Politics",
            description: "World affairs explained",
            imageURL: nil,
            articles: [],
            articleIDs: Set((1...5).map { "\($0)" }),
            readArticleIDs: ["1", "2", "3", "4", "5"],
            collectionType: .featured,
            isPremium: false,
            createdAt: fixedDate,
            updatedAt: fixedDate
        ))

        let view = CollectionCard(item: item) {}
            .padding()
            .background(LinearGradient.subtleBackground)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: componentConfig, precision: 0.99)),
            record: false
        )
    }

    func testCollectionCardNoProgress() {
        let item = CollectionViewItem(from: Collection(
            id: "test-no-progress",
            name: "Science Discovery",
            description: "Explore the universe",
            imageURL: nil,
            articles: [],
            articleIDs: Set((1...12).map { "\($0)" }),
            readArticleIDs: [],
            collectionType: .topic,
            isPremium: false,
            createdAt: fixedDate,
            updatedAt: fixedDate
        ))

        let view = CollectionCard(item: item) {}
            .padding()
            .background(LinearGradient.subtleBackground)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: componentConfig, precision: 0.99)),
            record: false
        )
    }

    func testCollectionCardUserType() {
        let item = CollectionViewItem(from: Collection(
            id: "test-user",
            name: "My Research",
            description: "Personal notes collection",
            imageURL: nil,
            articles: [],
            articleIDs: Set((1...3).map { "\($0)" }),
            readArticleIDs: ["1"],
            collectionType: .user,
            isPremium: false,
            createdAt: fixedDate,
            updatedAt: fixedDate
        ))

        let view = CollectionCard(item: item) {}
            .padding()
            .background(LinearGradient.subtleBackground)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: componentConfig, precision: 0.99)),
            record: false
        )
    }

    func testCollectionCardAICurated() {
        let item = CollectionViewItem(from: Collection(
            id: "test-ai",
            name: "AI Curated",
            description: "Personalized by AI",
            imageURL: nil,
            articles: [],
            articleIDs: Set((1...7).map { "\($0)" }),
            readArticleIDs: ["1", "2"],
            collectionType: .aiCurated,
            isPremium: true,
            createdAt: fixedDate,
            updatedAt: fixedDate
        ))

        let view = CollectionCard(item: item) {}
            .padding()
            .background(LinearGradient.subtleBackground)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: componentConfig, precision: 0.99)),
            record: false
        )
    }

    // MARK: - User Collection Row Tests

    func testUserCollectionRowDefault() {
        let item = CollectionViewItem(from: Collection(
            id: "user-1",
            name: "Research Notes",
            description: "Articles for my project",
            imageURL: nil,
            articles: [],
            articleIDs: Set((1...5).map { "\($0)" }),
            readArticleIDs: ["1"],
            collectionType: .user,
            isPremium: false,
            createdAt: fixedDate,
            updatedAt: fixedDate
        ))

        let view = UserCollectionRow(item: item, onTap: {}, onDelete: {})
            .padding()
            .background(LinearGradient.subtleBackground)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: rowConfig, precision: 0.99)),
            record: false
        )
    }

    func testUserCollectionRowCompleted() {
        let item = CollectionViewItem(from: Collection(
            id: "user-completed",
            name: "Finished Reading",
            description: "All articles read",
            imageURL: nil,
            articles: [],
            articleIDs: Set((1...3).map { "\($0)" }),
            readArticleIDs: ["1", "2", "3"],
            collectionType: .user,
            isPremium: false,
            createdAt: fixedDate,
            updatedAt: fixedDate
        ))

        let view = UserCollectionRow(item: item, onTap: {}, onDelete: {})
            .padding()
            .background(LinearGradient.subtleBackground)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: rowConfig, precision: 0.99)),
            record: false
        )
    }

    func testUserCollectionRowLongName() {
        let item = CollectionViewItem(from: Collection(
            id: "user-long",
            name: "This Is A Very Long Collection Name That Should Be Truncated",
            description: "A collection with a very long name",
            imageURL: nil,
            articles: [],
            articleIDs: Set((1...15).map { "\($0)" }),
            readArticleIDs: [],
            collectionType: .user,
            isPremium: false,
            createdAt: fixedDate,
            updatedAt: fixedDate
        ))

        let view = UserCollectionRow(item: item, onTap: {}, onDelete: {})
            .padding()
            .background(LinearGradient.subtleBackground)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: rowConfig, precision: 0.99)),
            record: false
        )
    }
}
