@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class DigestViewSnapshotTests: XCTestCase {
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
        serviceLocator.register(StorageService.self, instance: MockStorageService())
        serviceLocator.register(SummarizationService.self, instance: MockSummarizationService())
        serviceLocator.register(LLMService.self, instance: MockLLMService())
    }

    // MARK: - Empty State

    func testDigestViewEmpty() {
        let view = NavigationStack {
            DigestEmptyPreview()
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    // MARK: - Loading State

    func testDigestViewLoading() {
        let view = NavigationStack {
            DigestLoadingPreview()
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    // MARK: - Summaries List

    func testDigestViewWithSummaries() {
        let view = NavigationStack {
            DigestSummariesListPreview()
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    // MARK: - Error State

    func testDigestViewError() {
        let view = NavigationStack {
            DigestErrorPreview()
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }
}

// MARK: - Preview Helpers

private struct DigestEmptyPreview: View {
    var body: some View {
        ZStack {
            LinearGradient.subtleBackground.ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(Color.Accent.gradient.opacity(0.2))
                        .frame(width: 100, height: 100)

                    Image(systemName: "sparkles")
                        .font(.system(size: IconSize.xxl))
                        .foregroundStyle(Color.Accent.gradient)
                }

                VStack(spacing: Spacing.sm) {
                    Text("No Summaries Yet")
                        .font(Typography.titleMedium)

                    Text("Your AI-generated summaries will appear here")
                        .font(Typography.bodyMedium)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Text("Open an article and tap the sparkles button to create a summary")
                    .font(Typography.captionLarge)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }
            .padding(Spacing.xl)
        }
        .navigationTitle("Digest")
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

private struct DigestLoadingPreview: View {
    var body: some View {
        ZStack {
            LinearGradient.subtleBackground.ignoresSafeArea()

            VStack(spacing: Spacing.md) {
                ProgressView()
                    .tint(Color.Accent.primary)
                Text("Loading summaries...")
                    .font(Typography.bodySmall)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Digest")
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

private struct DigestSummariesListPreview: View {
    private let fixedDate = Date(timeIntervalSince1970: 1_672_531_200)

    private var mockItems: [SummaryItem] {
        [
            SummaryItem(
                article: Article(
                    id: "1",
                    title: "AI Revolution: How Machine Learning is Transforming Industries",
                    description: "From healthcare to finance, AI is reshaping the business landscape",
                    source: ArticleSource(id: "techcrunch", name: "TechCrunch"),
                    url: "https://example.com/1",
                    imageURL: nil,
                    publishedAt: fixedDate,
                    category: .technology
                ),
                summary: "AI is revolutionizing industries from healthcare to finance, with machine learning algorithms enabling new capabilities in diagnosis, trading, and automation.",
                generatedAt: fixedDate
            ),
            SummaryItem(
                article: Article(
                    id: "2",
                    title: "Apple Announces New MacBook Pro with M4 Chip",
                    description: "The latest MacBook Pro features unprecedented performance",
                    source: ArticleSource(id: "theverge", name: "The Verge"),
                    url: "https://example.com/2",
                    imageURL: nil,
                    publishedAt: fixedDate.addingTimeInterval(-3600),
                    category: .technology
                ),
                summary: "Apple's new M4 chip delivers significant performance improvements, making the new MacBook Pro the fastest laptop in the lineup.",
                generatedAt: fixedDate.addingTimeInterval(-3600)
            ),
            SummaryItem(
                article: Article(
                    id: "3",
                    title: "Swift 6 Brings Major Language Improvements",
                    description: "New concurrency features and performance optimizations",
                    source: ArticleSource(id: "hackingwithswift", name: "Hacking with Swift"),
                    url: "https://example.com/3",
                    imageURL: nil,
                    publishedAt: fixedDate.addingTimeInterval(-7200),
                    category: .technology
                ),
                summary: "Swift 6 introduces enhanced concurrency features and performance optimizations, making async/await patterns more intuitive.",
                generatedAt: fixedDate.addingTimeInterval(-7200)
            ),
        ]
    }

    var body: some View {
        ZStack {
            LinearGradient.subtleBackground.ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: Spacing.md) {
                    ForEach(mockItems) { item in
                        SummaryCardPreview(item: item)
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.lg)
            }
        }
        .navigationTitle("Digest")
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

private struct SummaryCardPreview: View {
    let item: SummaryItem
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Rectangle()
                .fill(Color.Glass.surface)
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous))
                .overlay {
                    Image(systemName: "newspaper")
                        .foregroundStyle(.tertiary)
                }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(spacing: Spacing.xxs) {
                    Image(systemName: "sparkles")
                        .font(.system(size: IconSize.xs))
                    Text("AI Summary")
                        .font(Typography.captionSmall)
                }
                .foregroundStyle(Color.Accent.primary)

                Text(item.article.title)
                    .font(Typography.headlineSmall)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack(spacing: Spacing.xs) {
                    Text(item.article.source.name)
                        .lineLimit(1)
                    Circle()
                        .fill(.tertiary)
                        .frame(width: 3, height: 3)
                    Text(item.formattedDate)
                        .lineLimit(1)
                }
                .font(Typography.captionLarge)
                .foregroundStyle(.tertiary)

                Text(item.summary)
                    .font(Typography.bodySmall)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassBackground(style: .solid, cornerRadius: CornerRadius.lg)
    }
}

private struct DigestErrorPreview: View {
    var body: some View {
        ZStack {
            LinearGradient.subtleBackground.ignoresSafeArea()

            VStack(spacing: Spacing.md) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: IconSize.xl))
                    .foregroundStyle(.orange)

                Text("Unable to load summaries")
                    .font(Typography.bodySmall)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button {} label: {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                    .font(Typography.labelMedium)
                    .foregroundStyle(Color.Accent.primary)
                }
            }
            .padding(Spacing.xl)
        }
        .navigationTitle("Digest")
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}
