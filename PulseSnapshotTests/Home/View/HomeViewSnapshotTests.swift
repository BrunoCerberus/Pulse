import EntropyCore
@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class HomeViewSnapshotTests: XCTestCase {
    private var serviceLocator: ServiceLocator!

    // Custom device config matching CI's iPhone Air simulator (forced dark mode)
    private let iPhoneAirConfig = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 393, height: 852),
        traits: UITraitCollection(userInterfaceStyle: .dark)
    )

    // Light mode config for additional coverage
    private let iPhoneAirLightConfig = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 393, height: 852),
        traits: UITraitCollection(userInterfaceStyle: .light)
    )

    // Fixed date for snapshot stability (Jan 1, 2023 - consistent relative time)
    private let fixedDate = Date(timeIntervalSince1970: 1_672_531_200)

    // Fixed date article for snapshot stability (Jan 1, 2023 - will always show consistent relative time)
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
            publishedAt: fixedDate,
            category: .technology
        )
    }

    // Article with very long title for text truncation testing
    private var longTitleArticle: Article {
        Article(
            id: "snapshot-long",
            title: "This Is An Extremely Long Article Title That Should Test How The UI Handles Text Truncation And Line Limits In The Article Row View Component",
            description: "A brief description that accompanies this article with the very long title to see how both elements render together.",
            content: "Full article content here...",
            author: "Jane Smith",
            source: ArticleSource(id: "reuters", name: "Reuters"),
            url: "https://example.com/2",
            imageURL: nil,
            publishedAt: fixedDate,
            category: .business
        )
    }

    // Article without description
    private var noDescriptionArticle: Article {
        Article(
            id: "snapshot-no-desc",
            title: "Breaking: Major Event Unfolds",
            description: nil,
            content: "Full article content here...",
            author: "News Desk",
            source: ArticleSource(id: "bbc", name: "BBC News"),
            url: "https://example.com/3",
            imageURL: nil,
            publishedAt: fixedDate,
            category: .world
        )
    }

    // Article with image URL
    private var articleWithImage: Article {
        Article(
            id: "snapshot-with-image",
            title: "Photo Story: Beautiful Landscapes",
            description: "Stunning photography captures nature's beauty.",
            content: "Full article content here...",
            author: "Photo Editor",
            source: ArticleSource(id: "natgeo", name: "National Geographic"),
            url: "https://example.com/4",
            imageURL: "https://picsum.photos/200/200",
            publishedAt: fixedDate,
            category: .science
        )
    }

    override func setUp() {
        super.setUp()
        serviceLocator = ServiceLocator()
        serviceLocator.register(NewsService.self, instance: MockNewsService())
        serviceLocator.register(StorageService.self, instance: MockStorageService())
    }

    // MARK: - HomeView Tests

    func testHomeViewLoading() {
        let view = HomeView(
            router: HomeNavigationRouter(),
            viewModel: HomeViewModel(serviceLocator: serviceLocator)
        )
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    // MARK: - ArticleRowView Tests

    func testArticleRowView() {
        let item = ArticleViewItem(from: snapshotArticle)
        let view = ArticleRowView(
            item: item,
            onTap: {},
            onBookmark: {},
            onShare: {}
        )
        .frame(width: 375)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    func testArticleRowViewLightMode() {
        let item = ArticleViewItem(from: snapshotArticle)
        let view = ArticleRowView(
            item: item,
            onTap: {},
            onBookmark: {},
            onShare: {}
        )
        .frame(width: 375)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirLightConfig, precision: 0.99)),
            record: false
        )
    }

    func testArticleRowViewLongTitle() {
        let item = ArticleViewItem(from: longTitleArticle)
        let view = ArticleRowView(
            item: item,
            onTap: {},
            onBookmark: {},
            onShare: {}
        )
        .frame(width: 375)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    func testArticleRowViewNoDescription() {
        let item = ArticleViewItem(from: noDescriptionArticle)
        let view = ArticleRowView(
            item: item,
            onTap: {},
            onBookmark: {},
            onShare: {}
        )
        .frame(width: 375)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    func testArticleRowViewWithImagePlaceholder() {
        // Test with image URL but no loaded image (shows placeholder)
        let item = ArticleViewItem(from: articleWithImage)
        let view = ArticleRowView(
            item: item,
            onTap: {},
            onBookmark: {},
            onShare: {}
        )
        .frame(width: 375)

        let controller = UIHostingController(rootView: view)

        // Short wait to show loading state
        assertSnapshot(
            of: controller,
            as: .wait(for: 0.1, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    func testArticleRowViewAllCategories() {
        let categories: [NewsCategory] = [.business, .entertainment, .health, .science, .sports, .technology]
        let views = categories.map { category -> ArticleRowView in
            let article = Article(
                id: "cat-\(category.rawValue)",
                title: "\(category.displayName) News Article",
                description: "Sample article in the \(category.displayName) category.",
                content: nil,
                author: nil,
                source: ArticleSource(id: nil, name: "Test Source"),
                url: "https://example.com",
                imageURL: nil,
                publishedAt: fixedDate,
                category: category
            )
            return ArticleRowView(
                item: ArticleViewItem(from: article),
                onTap: {},
                onBookmark: {},
                onShare: {}
            )
        }

        let view = VStack(spacing: 0) {
            ForEach(Array(views.enumerated()), id: \.offset) { _, row in
                row
            }
        }
        .frame(width: 375)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    // MARK: - BreakingNewsCard Tests

    func testBreakingNewsCard() {
        let item = ArticleViewItem(from: snapshotArticle)
        let view = BreakingNewsCard(item: item, onTap: {})
            .padding()

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    func testBreakingNewsCardLongTitle() {
        let item = ArticleViewItem(from: longTitleArticle)
        let view = BreakingNewsCard(item: item, onTap: {})
            .padding()

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    func testBreakingNewsCardLightMode() {
        let item = ArticleViewItem(from: snapshotArticle)
        let view = BreakingNewsCard(item: item, onTap: {})
            .padding()

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirLightConfig, precision: 0.99)),
            record: false
        )
    }

    // MARK: - ArticleSkeletonView Tests

    func testArticleSkeletonView() {
        let view = ArticleSkeletonView()
            .frame(width: 375)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    func testArticleSkeletonViewLightMode() {
        let view = ArticleSkeletonView()
            .frame(width: 375)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirLightConfig, precision: 0.99)),
            record: false
        )
    }

    func testArticleSkeletonViewMultiple() {
        let view = VStack(spacing: 0) {
            ForEach(0 ..< 3, id: \.self) { _ in
                ArticleSkeletonView()
            }
        }
        .frame(width: 375)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    // MARK: - Error State Tests

    func testHomeViewErrorState() {
        let view = NavigationStack {
            HomeErrorPreview()
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    func testHomeViewErrorStateLightMode() {
        let view = NavigationStack {
            HomeErrorPreview()
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirLightConfig, precision: 0.99)),
            record: false
        )
    }

    // MARK: - Empty State Tests

    func testHomeViewEmptyState() {
        let view = NavigationStack {
            HomeEmptyPreview()
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    // MARK: - Category Tabs Tests

    func testCategoryTabsWithFollowedTopics() {
        let view = NavigationStack {
            CategoryTabsPreview(
                followedTopics: [.technology, .business, .science],
                selectedCategory: nil
            )
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    func testCategoryTabsWithSelectedCategory() {
        let view = NavigationStack {
            CategoryTabsPreview(
                followedTopics: [.technology, .business, .science],
                selectedCategory: .technology
            )
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    func testCategoryTabsLightMode() {
        let view = NavigationStack {
            CategoryTabsPreview(
                followedTopics: [.technology, .business],
                selectedCategory: nil
            )
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirLightConfig, precision: 0.99)),
            record: false
        )
    }

    func testCategoryTabsAllCategories() {
        let view = NavigationStack {
            CategoryTabsPreview(
                followedTopics: NewsCategory.allCases,
                selectedCategory: .health
            )
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    func testCategoryTabsSingleTopic() {
        let view = NavigationStack {
            CategoryTabsPreview(
                followedTopics: [.technology],
                selectedCategory: nil
            )
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    func testNoCategoryTabsWhenNoFollowedTopics() {
        let view = NavigationStack {
            CategoryTabsPreview(
                followedTopics: [],
                selectedCategory: nil
            )
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }
}

// MARK: - Preview Helpers for State Testing

private struct HomeErrorPreview: View {
    var body: some View {
        ZStack {
            LinearGradient.subtleBackground
                .ignoresSafeArea()

            GlassCard(style: .thin, shadowStyle: .medium, padding: Spacing.xl) {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: IconSize.xxl))
                        .foregroundStyle(Color.Semantic.warning)

                    Text("Unable to Load News")
                        .font(Typography.titleMedium)

                    Text("Please check your internet connection and try again.")
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
        .navigationTitle("Home")
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

private struct HomeEmptyPreview: View {
    var body: some View {
        ZStack {
            LinearGradient.subtleBackground
                .ignoresSafeArea()

            GlassCard(style: .thin, shadowStyle: .medium, padding: Spacing.xl) {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "newspaper")
                        .font(.system(size: IconSize.xxl))
                        .foregroundStyle(.secondary)

                    Text("No Articles")
                        .font(Typography.titleMedium)

                    Text("No news articles are available right now. Pull to refresh.")
                        .font(Typography.bodyMedium)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(Spacing.lg)
        }
        .navigationTitle("Home")
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

private struct CategoryTabsPreview: View {
    let followedTopics: [NewsCategory]
    let selectedCategory: NewsCategory?

    var body: some View {
        ZStack {
            LinearGradient.subtleBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Category tabs (only shown when followedTopics is not empty)
                    if !followedTopics.isEmpty {
                        categoryTabBar
                    }

                    // Sample content
                    GlassSectionHeader("Top Headlines")

                    VStack(spacing: Spacing.sm) {
                        ForEach(0 ..< 3, id: \.self) { index in
                            sampleArticleCard(index: index)
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                }
            }
        }
        .navigationTitle("News")
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    private var categoryTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                // "All" tab - always first
                Button {} label: {
                    Text("All")
                        .font(Typography.labelMedium)
                        .foregroundStyle(selectedCategory == nil ? .white : Color.Accent.primary)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.xs)
                        .background {
                            Capsule()
                                .fill(selectedCategory == nil ? Color.Accent.primary : Color.Accent.primary.opacity(0.15))
                        }
                }

                // Followed topics tabs
                ForEach(followedTopics, id: \.self) { category in
                    Button {} label: {
                        Text(category.displayName)
                            .font(Typography.labelMedium)
                            .foregroundStyle(selectedCategory == category ? .white : category.color)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.xs)
                            .background {
                                Capsule()
                                    .fill(selectedCategory == category ? category.color : category.color.opacity(0.15))
                            }
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
        }
    }

    private func sampleArticleCard(index: Int) -> some View {
        GlassCard(style: .thin, shadowStyle: .subtle, padding: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Sample Article Title \(index + 1)")
                    .font(Typography.titleSmall)

                Text("This is a sample article description for testing purposes.")
                    .font(Typography.bodySmall)
                    .foregroundStyle(.secondary)

                HStack {
                    Text("Source")
                        .font(Typography.captionMedium)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("2h ago")
                        .font(Typography.captionMedium)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
