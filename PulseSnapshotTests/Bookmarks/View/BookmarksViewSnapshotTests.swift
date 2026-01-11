@testable import Pulse
import EntropyCore
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class BookmarksViewSnapshotTests: XCTestCase {
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
        serviceLocator.register(BookmarksService.self, instance: MockBookmarksService())
        serviceLocator.register(StorageService.self, instance: MockStorageService())
    }

    // MARK: - Empty State

    func testBookmarksViewEmpty() {
        let view = NavigationStack {
            BookmarksView(
                router: BookmarksNavigationRouter(),
                viewModel: BookmarksViewModel(serviceLocator: serviceLocator)
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

    func testBookmarksViewLoading() {
        let view = NavigationStack {
            BookmarksLoadingPreview()
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    // MARK: - Error State

    func testBookmarksViewError() {
        let view = NavigationStack {
            BookmarksErrorPreview()
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    // MARK: - Populated State

    func testBookmarksViewPopulated() {
        let view = NavigationStack {
            BookmarksPopulatedPreview()
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.5, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    // MARK: - Empty State View Only

    func testBookmarksViewEmptyState() {
        let view = NavigationStack {
            BookmarksEmptyStatePreview()
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

private struct BookmarksLoadingPreview: View {
    var body: some View {
        ZStack {
            LinearGradient.subtleBackground
                .ignoresSafeArea()

            VStack(spacing: Spacing.md) {
                ProgressView()
                    .scaleEffect(1.2)
                Text("Loading bookmarks...")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("Bookmarks")
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

private struct BookmarksErrorPreview: View {
    var body: some View {
        ZStack {
            LinearGradient.subtleBackground
                .ignoresSafeArea()

            GlassCard(style: .thin, shadowStyle: .medium, padding: Spacing.xl) {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: IconSize.xxl))
                        .foregroundStyle(Color.Semantic.warning)

                    Text("Unable to Load Bookmarks")
                        .font(Typography.titleMedium)

                    Text("Something went wrong while loading your bookmarks. Please try again.")
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
        .navigationTitle("Bookmarks")
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

private struct BookmarksEmptyStatePreview: View {
    var body: some View {
        ZStack {
            LinearGradient.subtleBackground
                .ignoresSafeArea()

            GlassCard(style: .thin, shadowStyle: .medium, padding: Spacing.xl) {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "bookmark")
                        .font(.system(size: IconSize.xxl))
                        .foregroundStyle(Color.Accent.primary)

                    Text("No Bookmarks")
                        .font(Typography.titleMedium)

                    Text("Articles you bookmark will appear here for offline reading.")
                        .font(Typography.bodyMedium)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(Spacing.lg)
        }
        .navigationTitle("Bookmarks")
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

private struct BookmarksPopulatedPreview: View {
    private let fixedDate = Date(timeIntervalSince1970: 1_672_531_200)

    private var mockBookmarks: [ArticleViewItem] {
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
                title: "Climate Summit Reaches Historic Agreement",
                description: "World leaders commit to ambitious carbon reduction targets",
                source: ArticleSource(id: "reuters", name: "Reuters"),
                url: "https://example.com/2",
                imageURL: nil,
                publishedAt: fixedDate,
                category: .world
            )),
            ArticleViewItem(from: Article(
                id: "3",
                title: "New Study Links Exercise to Improved Mental Health",
                description: "Research shows regular physical activity reduces anxiety symptoms",
                source: ArticleSource(id: "bbc", name: "BBC Health"),
                url: "https://example.com/3",
                imageURL: nil,
                publishedAt: fixedDate,
                category: .health
            )),
            ArticleViewItem(from: Article(
                id: "4",
                title: "Championship Finals Set New Viewership Records",
                description: "Historic game draws millions of viewers worldwide",
                source: ArticleSource(id: "espn", name: "ESPN"),
                url: "https://example.com/4",
                imageURL: nil,
                publishedAt: fixedDate,
                category: .sports
            )),
        ]
    }

    var body: some View {
        ZStack {
            LinearGradient.subtleBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.sm) {
                    HStack {
                        Image(systemName: "bookmark.fill")
                            .foregroundStyle(Color.Accent.primary)
                        Text("\(mockBookmarks.count) saved articles")
                            .font(Typography.captionLarge)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, Spacing.xs)
                    .padding(.bottom, Spacing.xs)

                    ForEach(mockBookmarks, id: \.id) { item in
                        GlassArticleCard(
                            item: item,
                            isBookmarked: true,
                            onTap: {},
                            onBookmark: {},
                            onShare: {}
                        )
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.sm)
            }
        }
        .navigationTitle("Bookmarks")
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}
