@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class CategoriesViewSnapshotTests: XCTestCase {
    private var serviceLocator: ServiceLocator!

    // Custom device config matching CI's iPhone Air simulator
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
        serviceLocator.register(NewsService.self, instance: MockNewsService())
        serviceLocator.register(CategoriesService.self, instance: MockCategoriesService())
        serviceLocator.register(StorageService.self, instance: MockStorageService())
    }

    // MARK: - Initial State (No Category Selected)

    func testCategoriesViewInitial() {
        let view = NavigationStack {
            CategoriesView(
                router: CategoriesNavigationRouter(),
                viewModel: CategoriesViewModel(serviceLocator: serviceLocator)
            )
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.98)),
            record: false
        )
    }

    // MARK: - Select Category Prompt

    func testCategoriesViewSelectPrompt() {
        let view = NavigationStack {
            CategoriesSelectPromptPreview()
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.98)),
            record: false
        )
    }

    // MARK: - Loading State

    func testCategoriesViewLoading() {
        let view = NavigationStack {
            CategoriesLoadingPreview()
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.98)),
            record: false
        )
    }

    // MARK: - Error State

    func testCategoriesViewError() {
        let view = NavigationStack {
            CategoriesErrorPreview()
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.98)),
            record: false
        )
    }

    // MARK: - Empty State

    func testCategoriesViewEmpty() {
        let view = NavigationStack {
            CategoriesEmptyPreview()
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.98)),
            record: false
        )
    }

    // MARK: - Populated State with Category Selected

    func testCategoriesViewWithArticles() {
        let view = NavigationStack {
            CategoriesPopulatedPreview()
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.5, on: .image(on: iPhoneAirConfig, precision: 0.95)),
            record: false
        )
    }

    // MARK: - Different Category Backgrounds

    func testCategoriesViewTechnologyBackground() {
        let view = NavigationStack {
            CategoriesCategoryBackgroundPreview(category: .technology)
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.98)),
            record: false
        )
    }

    func testCategoriesViewHealthBackground() {
        let view = NavigationStack {
            CategoriesCategoryBackgroundPreview(category: .health)
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.98)),
            record: false
        )
    }

    func testCategoriesViewSportsBackground() {
        let view = NavigationStack {
            CategoriesCategoryBackgroundPreview(category: .sports)
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.98)),
            record: false
        )
    }
}

// MARK: - Preview Helpers for State Testing

private struct CategoriesSelectPromptPreview: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                Section {
                    GlassCard(style: .thin, shadowStyle: .medium, padding: Spacing.xl) {
                        VStack(spacing: Spacing.md) {
                            Image(systemName: "square.grid.2x2")
                                .font(.system(size: IconSize.xxl))
                                .foregroundStyle(Color.Accent.primary)

                            Text("Select a Category")
                                .font(Typography.titleMedium)

                            Text("Choose a category above to see related articles.")
                                .font(Typography.bodyMedium)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, Spacing.lg)
                    .containerRelativeFrame(.vertical) { height, _ in
                        height * 0.6
                    }
                } header: {
                    categoryChipsRow(selectedCategory: nil)
                }
            }
        }
        .background(LinearGradient.subtleBackground.ignoresSafeArea())
        .navigationTitle("Categories")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

private struct CategoriesLoadingPreview: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                Section {
                    VStack(spacing: Spacing.md) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading articles...")
                            .font(Typography.bodyMedium)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .containerRelativeFrame(.vertical) { height, _ in
                        height * 0.6
                    }
                    .padding(.top, Spacing.sm)
                } header: {
                    categoryChipsRow(selectedCategory: .technology)
                }
            }
        }
        .background {
            LinearGradient(
                colors: [
                    NewsCategory.technology.color.opacity(0.1),
                    Color(.systemBackground),
                ],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()
        }
        .navigationTitle("Categories")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

private struct CategoriesErrorPreview: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                Section {
                    GlassCard(style: .thin, shadowStyle: .medium, padding: Spacing.xl) {
                        VStack(spacing: Spacing.md) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: IconSize.xxl))
                                .foregroundStyle(Color.Semantic.warning)

                            Text("Error")
                                .font(Typography.titleMedium)

                            Text("Failed to load articles. Please check your connection and try again.")
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
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, Spacing.lg)
                    .containerRelativeFrame(.vertical) { height, _ in
                        height * 0.6
                    }
                    .padding(.top, Spacing.sm)
                } header: {
                    categoryChipsRow(selectedCategory: .technology)
                }
            }
        }
        .background {
            LinearGradient(
                colors: [
                    NewsCategory.technology.color.opacity(0.1),
                    Color(.systemBackground),
                ],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()
        }
        .navigationTitle("Categories")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

private struct CategoriesEmptyPreview: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                Section {
                    GlassCard(style: .thin, shadowStyle: .medium, padding: Spacing.xl) {
                        VStack(spacing: Spacing.md) {
                            Image(systemName: "newspaper")
                                .font(.system(size: IconSize.xxl))
                                .foregroundStyle(.secondary)

                            Text("No Articles")
                                .font(Typography.titleMedium)

                            Text("No articles found in this category.")
                                .font(Typography.bodyMedium)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, Spacing.lg)
                    .containerRelativeFrame(.vertical) { height, _ in
                        height * 0.6
                    }
                    .padding(.top, Spacing.sm)
                } header: {
                    categoryChipsRow(selectedCategory: .entertainment)
                }
            }
        }
        .background {
            LinearGradient(
                colors: [
                    NewsCategory.entertainment.color.opacity(0.1),
                    Color(.systemBackground),
                ],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()
        }
        .navigationTitle("Categories")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

private struct CategoriesPopulatedPreview: View {
    private let fixedDate = Date(timeIntervalSince1970: 1_672_531_200)

    private var mockArticles: [ArticleViewItem] {
        [
            ArticleViewItem(from: Article(
                id: "1",
                title: "AI Revolution: How Machine Learning is Transforming Industries",
                description: "From healthcare to finance, AI is reshaping the business landscape",
                source: ArticleSource(id: "techcrunch", name: "TechCrunch"),
                url: "https://example.com/1",
                imageURL: "https://picsum.photos/400/300",
                publishedAt: fixedDate,
                category: .technology
            )),
            ArticleViewItem(from: Article(
                id: "2",
                title: "Apple Announces New MacBook Pro with M4 Chip",
                description: "The latest MacBook Pro features unprecedented performance",
                source: ArticleSource(id: "theverge", name: "The Verge"),
                url: "https://example.com/2",
                imageURL: "https://picsum.photos/400/301",
                publishedAt: fixedDate,
                category: .technology
            )),
            ArticleViewItem(from: Article(
                id: "3",
                title: "Swift 6 Brings Major Language Improvements",
                description: "New concurrency features and performance optimizations",
                source: ArticleSource(id: "hackingwithswift", name: "Hacking with Swift"),
                url: "https://example.com/3",
                imageURL: "https://picsum.photos/400/302",
                publishedAt: fixedDate,
                category: .technology
            )),
        ]
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                Section {
                    LazyVStack(spacing: Spacing.sm) {
                        HStack {
                            Text("\(mockArticles.count) articles")
                                .font(Typography.captionLarge)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.bottom, Spacing.xs)

                        ForEach(mockArticles, id: \.id) { item in
                            GlassArticleCard(
                                item: item,
                                onTap: {},
                                onBookmark: {},
                                onShare: {}
                            )
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.sm)
                } header: {
                    categoryChipsRow(selectedCategory: .technology)
                }
            }
        }
        .background {
            LinearGradient(
                colors: [
                    NewsCategory.technology.color.opacity(0.1),
                    Color(.systemBackground),
                ],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()
        }
        .navigationTitle("Categories")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

private struct CategoriesCategoryBackgroundPreview: View {
    let category: NewsCategory

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                Section {
                    VStack(spacing: Spacing.md) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading \(category.displayName) articles...")
                            .font(Typography.bodyMedium)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .containerRelativeFrame(.vertical) { height, _ in
                        height * 0.6
                    }
                    .padding(.top, Spacing.sm)
                } header: {
                    categoryChipsRow(selectedCategory: category)
                }
            }
        }
        .background {
            LinearGradient(
                colors: [
                    category.color.opacity(0.1),
                    Color(.systemBackground),
                ],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()
        }
        .navigationTitle("Categories")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

// MARK: - Shared Helper

private func categoryChipsRow(selectedCategory: NewsCategory?) -> some View {
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: Spacing.sm) {
            ForEach(NewsCategory.allCases, id: \.self) { category in
                GlassCategoryChip(
                    category: category,
                    style: .medium,
                    isSelected: category == selectedCategory,
                    showIcon: true
                )
            }
        }
        .padding(.horizontal, Spacing.md)
    }
    .padding(.vertical, Spacing.sm)
    .background(.ultraThinMaterial)
}
