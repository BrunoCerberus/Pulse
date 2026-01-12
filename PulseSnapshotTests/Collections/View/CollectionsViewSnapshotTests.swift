import EntropyCore
@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class CollectionsViewSnapshotTests: XCTestCase {
    private var serviceLocator: ServiceLocator!

    // Custom device config matching CI's iPhone Air simulator (forced dark mode)
    private let iPhoneAirConfig = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 393, height: 852),
        traits: UITraitCollection(userInterfaceStyle: .dark)
    )

    // Fixed date for snapshot stability
    private let fixedDate = Date(timeIntervalSince1970: 1_672_531_200) // Jan 1, 2023 00:00:00 UTC

    override func setUp() {
        super.setUp()
        serviceLocator = ServiceLocator()
        serviceLocator.register(CollectionsService.self, instance: MockCollectionsService())
        serviceLocator.register(StorageService.self, instance: MockStorageService())
    }

    // MARK: - Loading State

    func testCollectionsViewLoading() {
        let view = NavigationStack {
            CollectionsView(
                router: CollectionsNavigationRouter(),
                viewModel: CollectionsViewModel(serviceLocator: serviceLocator)
            )
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    // MARK: - Empty State

    func testCollectionsViewEmpty() {
        let view = NavigationStack {
            CollectionsEmptyPreview()
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    // MARK: - Error State

    func testCollectionsViewError() {
        let view = NavigationStack {
            CollectionsErrorPreview()
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    // MARK: - Populated State

    func testCollectionsViewPopulated() {
        let view = NavigationStack {
            CollectionsPopulatedPreview()
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.5, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    // MARK: - Empty User Collections State

    func testCollectionsViewEmptyUserCollections() {
        let view = NavigationStack {
            CollectionsEmptyUserPreview()
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.5, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }
}

// MARK: - Preview Helpers for State Testing

private struct CollectionsEmptyPreview: View {
    var body: some View {
        ZStack {
            LinearGradient.subtleBackground
                .ignoresSafeArea()

            GlassCard(style: .thin, shadowStyle: .medium, padding: Spacing.xl) {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "rectangle.stack")
                        .font(.system(size: IconSize.xxl))
                        .foregroundStyle(.secondary)

                    Text("No Collections Yet")
                        .font(Typography.titleMedium)

                    Text("Create your first collection to organize articles by topic.")
                        .font(Typography.bodyMedium)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button {} label: {
                        HStack {
                            Image(systemName: "plus")
                            Text("New Collection")
                        }
                        .font(Typography.labelLarge)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm)
                        .background(Color.Accent.primary)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Spacing.lg)
        }
        .navigationTitle("Collections")
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

private struct CollectionsErrorPreview: View {
    var body: some View {
        ZStack {
            LinearGradient.subtleBackground
                .ignoresSafeArea()

            GlassCard(style: .thin, shadowStyle: .medium, padding: Spacing.xl) {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: IconSize.xxl))
                        .foregroundStyle(Color.Semantic.warning)

                    Text("Something went wrong")
                        .font(Typography.titleMedium)

                    Text("Unable to load collections. Please check your connection and try again.")
                        .font(Typography.bodyMedium)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button {} label: {
                        Text("Try Again")
                            .font(Typography.labelLarge)
                            .foregroundStyle(.white)
                            .padding(.horizontal, Spacing.lg)
                            .padding(.vertical, Spacing.sm)
                            .background(Color.Accent.primary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Spacing.lg)
        }
        .navigationTitle("Collections")
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

private struct CollectionsPopulatedPreview: View {
    private let fixedDate = Date(timeIntervalSince1970: 1_672_531_200)

    private var mockFeaturedCollections: [CollectionViewItem] {
        [
            CollectionViewItem(from: Collection(
                id: "climate-crisis",
                name: "Climate Crisis",
                description: "Understand the science and solutions",
                imageURL: nil,
                articles: [],
                articleCount: 10,
                readArticleIDs: ["1", "2", "3"],
                collectionType: .featured,
                isPremium: false,
                createdAt: fixedDate,
                updatedAt: fixedDate
            )),
            CollectionViewItem(from: Collection(
                id: "ai-tech",
                name: "AI & Technology",
                description: "Latest in artificial intelligence",
                imageURL: nil,
                articles: [],
                articleCount: 8,
                readArticleIDs: [],
                collectionType: .featured,
                isPremium: true,
                createdAt: fixedDate,
                updatedAt: fixedDate
            )),
            CollectionViewItem(from: Collection(
                id: "global-politics",
                name: "Global Politics",
                description: "World affairs explained",
                imageURL: nil,
                articles: [],
                articleCount: 12,
                readArticleIDs: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12"],
                collectionType: .featured,
                isPremium: false,
                createdAt: fixedDate,
                updatedAt: fixedDate
            )),
        ]
    }

    private var mockUserCollections: [CollectionViewItem] {
        [
            CollectionViewItem(from: Collection(
                id: "user-research",
                name: "Research Notes",
                description: "Articles for my project",
                imageURL: nil,
                articles: [],
                articleCount: 5,
                readArticleIDs: ["1"],
                collectionType: .user,
                isPremium: false,
                createdAt: fixedDate,
                updatedAt: fixedDate
            )),
            CollectionViewItem(from: Collection(
                id: "user-later",
                name: "Read Later",
                description: "Saved for later reading",
                imageURL: nil,
                articles: [],
                articleCount: 12,
                readArticleIDs: [],
                collectionType: .user,
                isPremium: false,
                createdAt: fixedDate,
                updatedAt: fixedDate
            )),
        ]
    }

    var body: some View {
        ZStack {
            LinearGradient.subtleBackground
                .ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    Section {
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: Spacing.md) {
                                ForEach(mockFeaturedCollections) { item in
                                    CollectionCard(item: item) {}
                                }
                            }
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                        }
                    } header: {
                        GlassSectionHeader("Featured")
                    }

                    Section {
                        VStack(spacing: Spacing.sm) {
                            ForEach(mockUserCollections) { item in
                                UserCollectionRow(item: item, onTap: {}, onDelete: {})
                            }
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.top, Spacing.sm)
                    } header: {
                        HStack {
                            GlassSectionHeader("My Collections")
                            Spacer()
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: IconSize.lg))
                                .foregroundStyle(Color.Accent.primary)
                                .padding(.trailing, Spacing.md)
                        }
                    }

                    GlassCard(style: .thick, shadowStyle: .medium, padding: Spacing.lg) {
                        HStack(spacing: Spacing.md) {
                            Image(systemName: "sparkles")
                                .font(.system(size: IconSize.xl))
                                .foregroundStyle(Color.Accent.gold)

                            VStack(alignment: .leading, spacing: Spacing.xxs) {
                                HStack {
                                    Text("Premium Collections")
                                        .font(Typography.titleSmall)
                                    PremiumBadge()
                                }
                                Text("Unlock AI-curated collections")
                                    .font(Typography.captionLarge)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: IconSize.sm))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.lg)
                }
            }
        }
        .navigationTitle("Collections")
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

private struct CollectionsEmptyUserPreview: View {
    private let fixedDate = Date(timeIntervalSince1970: 1_672_531_200)

    private var mockFeaturedCollections: [CollectionViewItem] {
        [
            CollectionViewItem(from: Collection(
                id: "climate-crisis",
                name: "Climate Crisis",
                description: "Understand the science and solutions",
                imageURL: nil,
                articles: [],
                articleCount: 10,
                readArticleIDs: ["1", "2", "3"],
                collectionType: .featured,
                isPremium: false,
                createdAt: fixedDate,
                updatedAt: fixedDate
            )),
            CollectionViewItem(from: Collection(
                id: "ai-tech",
                name: "AI & Technology",
                description: "Latest in artificial intelligence",
                imageURL: nil,
                articles: [],
                articleCount: 8,
                readArticleIDs: [],
                collectionType: .featured,
                isPremium: true,
                createdAt: fixedDate,
                updatedAt: fixedDate
            )),
        ]
    }

    var body: some View {
        ZStack {
            LinearGradient.subtleBackground
                .ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    Section {
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: Spacing.md) {
                                ForEach(mockFeaturedCollections) { item in
                                    CollectionCard(item: item) {}
                                }
                            }
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                        }
                    } header: {
                        GlassSectionHeader("Featured")
                    }

                    Section {
                        GlassCard(style: .ultraThin, shadowStyle: .subtle, padding: Spacing.lg) {
                            VStack(spacing: Spacing.sm) {
                                Image(systemName: "folder.badge.plus")
                                    .font(.system(size: IconSize.xl))
                                    .foregroundStyle(.secondary)

                                Text("No Personal Collections")
                                    .font(Typography.titleSmall)

                                Text("Tap + to create your first collection")
                                    .font(Typography.captionLarge)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.top, Spacing.sm)
                    } header: {
                        HStack {
                            GlassSectionHeader("My Collections")
                            Spacer()
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: IconSize.lg))
                                .foregroundStyle(Color.Accent.primary)
                                .padding(.trailing, Spacing.md)
                        }
                    }
                }
            }
        }
        .navigationTitle("Collections")
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}
