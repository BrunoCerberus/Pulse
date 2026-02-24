import EntropyCore
@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class ReadingHistoryViewSnapshotTests: XCTestCase {
    private var serviceLocator: ServiceLocator!

    /// Fixed date for snapshot stability
    private let fixedDate = Date(timeIntervalSince1970: 1_672_531_200) // Jan 1, 2023 00:00:00 UTC

    override func setUp() {
        super.setUp()
        serviceLocator = ServiceLocator()
        serviceLocator.register(StorageService.self, instance: MockStorageService())
    }

    // MARK: - Empty State

    func testReadingHistoryViewEmpty() {
        let view = NavigationStack {
            ReadingHistoryView(
                router: ReadingHistoryNavigationRouter(),
                viewModel: ReadingHistoryViewModel(serviceLocator: serviceLocator)
            )
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: SnapshotConfig.iPhoneAir),
            record: false
        )
    }

    func testReadingHistoryViewEmptyLightMode() {
        let view = NavigationStack {
            ReadingHistoryView(
                router: ReadingHistoryNavigationRouter(),
                viewModel: ReadingHistoryViewModel(serviceLocator: serviceLocator)
            )
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: SnapshotConfig.iPhoneAirLight),
            record: false
        )
    }

    // MARK: - Loading State

    func testReadingHistoryViewLoading() {
        let view = NavigationStack {
            ReadingHistoryLoadingPreview()
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: SnapshotConfig.iPhoneAir),
            record: false
        )
    }

    // MARK: - Error State

    func testReadingHistoryViewError() {
        let view = NavigationStack {
            ReadingHistoryErrorPreview()
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: SnapshotConfig.iPhoneAir),
            record: false
        )
    }

    // MARK: - Populated State

    func testReadingHistoryViewPopulated() {
        let view = NavigationStack {
            ReadingHistoryPopulatedPreview()
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: SnapshotConfig.iPhoneAir),
            record: false
        )
    }

    func testReadingHistoryViewPopulatedLightMode() {
        let view = NavigationStack {
            ReadingHistoryPopulatedPreview()
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: SnapshotConfig.iPhoneAirLight),
            record: false
        )
    }
}

// MARK: - Preview Helpers for State Testing

private struct ReadingHistoryLoadingPreview: View {
    var body: some View {
        ZStack {
            LinearGradient.subtleBackground
                .ignoresSafeArea()

            VStack(spacing: Spacing.md) {
                ProgressView()
                    .scaleEffect(1.2)
                Text("Loading history...")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("Reading History")
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

private struct ReadingHistoryErrorPreview: View {
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

                    Text("Something went wrong while loading your reading history. Please try again.")
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
        .navigationTitle("Reading History")
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

private struct ReadingHistoryEmptyStatePreview: View {
    var body: some View {
        ZStack {
            LinearGradient.subtleBackground
                .ignoresSafeArea()

            GlassCard(style: .thin, shadowStyle: .medium, padding: Spacing.xl) {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: IconSize.xxl))
                        .foregroundStyle(Color.Accent.primary)

                    Text("No Reading History")
                        .font(Typography.titleMedium)

                    Text("Articles you read will appear here.")
                        .font(Typography.bodyMedium)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(Spacing.lg)
        }
        .navigationTitle("Reading History")
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

private struct ReadingHistoryPopulatedPreview: View {
    private let fixedDate = Date(timeIntervalSince1970: 1_672_531_200)

    private var mockArticles: [ArticleViewItem] {
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
            ), isRead: true),
            ArticleViewItem(from: Article(
                id: "2",
                title: "Climate Summit Reaches Historic Agreement",
                description: "World leaders commit to ambitious carbon reduction targets",
                source: ArticleSource(id: "reuters", name: "Reuters"),
                url: "https://example.com/2",
                imageURL: nil,
                publishedAt: fixedDate,
                category: .world
            ), isRead: true),
            ArticleViewItem(from: Article(
                id: "3",
                title: "New Study Links Exercise to Improved Mental Health",
                description: "Research shows regular physical activity reduces anxiety symptoms",
                source: ArticleSource(id: "bbc", name: "BBC Health"),
                url: "https://example.com/3",
                imageURL: nil,
                publishedAt: fixedDate,
                category: .health
            ), isRead: true),
            ArticleViewItem(from: Article(
                id: "4",
                title: "Championship Finals Set New Viewership Records",
                description: "Historic game draws millions of viewers worldwide",
                source: ArticleSource(id: "espn", name: "ESPN"),
                url: "https://example.com/4",
                imageURL: nil,
                publishedAt: fixedDate,
                category: .sports
            ), isRead: true),
        ]
    }

    var body: some View {
        ZStack {
            LinearGradient.subtleBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.sm) {
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
            }
        }
        .navigationTitle("Reading History")
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}
