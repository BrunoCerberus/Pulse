@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class SearchViewSnapshotTests: XCTestCase {
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
        serviceLocator.register(SearchService.self, instance: MockSearchService())
        serviceLocator.register(StorageService.self, instance: MockStorageService())
    }

    // MARK: - Initial State

    func testSearchViewInitial() {
        let view = NavigationStack {
            SearchView(
                router: SearchNavigationRouter(),
                viewModel: SearchViewModel(serviceLocator: serviceLocator)
            )
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    // MARK: - Loading State

    func testSearchViewLoading() {
        let view = NavigationStack {
            SearchLoadingPreview()
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    // MARK: - Error State

    func testSearchViewError() {
        let view = NavigationStack {
            SearchErrorPreview()
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    // MARK: - No Results State

    func testSearchViewNoResults() {
        let view = NavigationStack {
            SearchNoResultsPreview()
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    // MARK: - Results State

    func testSearchViewWithResults() {
        let view = NavigationStack {
            SearchResultsPreview()
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.5, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    // MARK: - Suggestions State

    func testSearchViewSuggestions() {
        let view = NavigationStack {
            SearchSuggestionsPreview()
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

private struct SearchLoadingPreview: View {
    var body: some View {
        ZStack {
            LinearGradient.subtleBackground
                .ignoresSafeArea()

            VStack(spacing: Spacing.md) {
                ProgressView()
                    .scaleEffect(1.2)
                Text("Searching...")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("Search")
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

private struct SearchErrorPreview: View {
    var body: some View {
        ZStack {
            LinearGradient.subtleBackground
                .ignoresSafeArea()

            GlassCard(style: .thin, shadowStyle: .medium, padding: Spacing.xl) {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: IconSize.xxl))
                        .foregroundStyle(Color.Semantic.error)

                    Text("Search Failed")
                        .font(Typography.titleMedium)

                    Text("Unable to complete search. Please check your connection and try again.")
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
                }
            }
            .padding(Spacing.lg)
        }
        .navigationTitle("Search")
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

private struct SearchNoResultsPreview: View {
    var body: some View {
        ZStack {
            LinearGradient.subtleBackground
                .ignoresSafeArea()

            GlassCard(style: .thin, shadowStyle: .medium, padding: Spacing.xl) {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: IconSize.xxl))
                        .foregroundStyle(.secondary)

                    Text("No Results Found")
                        .font(Typography.titleMedium)

                    Text("No articles found for \"quantum computing\"")
                        .font(Typography.bodyMedium)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(Spacing.lg)
        }
        .navigationTitle("Search")
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

private struct SearchResultsPreview: View {
    private let fixedDate = Date(timeIntervalSince1970: 1_672_531_200)

    private var mockResults: [ArticleViewItem] {
        [
            ArticleViewItem(from: Article(
                id: "1",
                title: "SwiftUI 6.0 Brings Revolutionary New Features",
                description: "Apple announces major updates to SwiftUI at WWDC 2024",
                source: ArticleSource(id: "techcrunch", name: "TechCrunch"),
                url: "https://example.com/1",
                imageURL: nil,
                publishedAt: fixedDate,
                category: .technology
            )),
            ArticleViewItem(from: Article(
                id: "2",
                title: "iOS Development Best Practices for 2024",
                description: "Essential tips for building modern iOS applications",
                source: ArticleSource(id: "raywenderlich", name: "Ray Wenderlich"),
                url: "https://example.com/2",
                imageURL: nil,
                publishedAt: fixedDate,
                category: .technology
            )),
            ArticleViewItem(from: Article(
                id: "3",
                title: "Swift Concurrency Deep Dive",
                description: "Understanding async/await and actors in Swift",
                source: ArticleSource(id: "hackingwithswift", name: "Hacking with Swift"),
                url: "https://example.com/3",
                imageURL: nil,
                publishedAt: fixedDate,
                category: .technology
            )),
        ]
    }

    var body: some View {
        ZStack {
            LinearGradient.subtleBackground
                .ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: Spacing.md) {
                    Picker("Sort by", selection: .constant(SearchSortOption.relevancy)) {
                        ForEach(SearchSortOption.allCases) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, Spacing.md)

                    LazyVStack(spacing: Spacing.sm) {
                        ForEach(mockResults, id: \.id) { item in
                            GlassArticleCard(
                                item: item,
                                onTap: {},
                                onBookmark: {},
                                onShare: {}
                            )
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                }
                .padding(.top, Spacing.sm)
            }
        }
        .navigationTitle("Search")
        .toolbarBackground(.hidden, for: .navigationBar)
        .searchable(text: .constant("SwiftUI"), prompt: "Search news...")
    }
}

private struct SearchSuggestionsPreview: View {
    private var suggestions: [String] {
        ["Swift", "iOS 18", "Apple Vision Pro", "WWDC 2024"]
    }

    var body: some View {
        ZStack {
            LinearGradient.subtleBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.lg) {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        GlassSectionHeader("Recent Searches")

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Spacing.sm) {
                                ForEach(suggestions, id: \.self) { suggestion in
                                    Button {} label: {
                                        HStack(spacing: Spacing.xs) {
                                            Image(systemName: "clock")
                                                .font(.system(size: IconSize.sm))
                                            Text(suggestion)
                                                .font(Typography.labelMedium)
                                        }
                                        .foregroundStyle(.primary)
                                        .padding(.horizontal, Spacing.md)
                                        .padding(.vertical, Spacing.xs)
                                        .glassBackground(style: .thin, cornerRadius: CornerRadius.pill)
                                    }
                                }
                            }
                            .padding(.horizontal, Spacing.md)
                        }
                    }

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        GlassSectionHeader("Trending Topics")

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: Spacing.sm) {
                            ForEach(NewsCategory.allCases) { category in
                                GlassCategoryButton(category: category, isSelected: false) {}
                            }
                        }
                        .padding(.horizontal, Spacing.md)
                    }
                }
                .padding(.top, Spacing.md)
            }
        }
        .navigationTitle("Search")
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}
