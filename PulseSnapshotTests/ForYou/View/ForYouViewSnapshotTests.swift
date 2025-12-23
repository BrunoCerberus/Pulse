@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class ForYouViewSnapshotTests: XCTestCase {
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
        serviceLocator.register(ForYouService.self, instance: MockForYouService())
        serviceLocator.register(SettingsService.self, instance: MockSettingsService())
        serviceLocator.register(StorageService.self, instance: MockStorageService())
    }

    // MARK: - Loading State

    func testForYouViewLoading() {
        let view = NavigationStack {
            ForYouView(
                router: ForYouNavigationRouter(),
                viewModel: ForYouViewModel(serviceLocator: serviceLocator)
            )
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: iPhoneAirConfig, precision: 0.95)),
            record: false
        )
    }

    // MARK: - Onboarding State

    func testForYouViewOnboarding() {
        let view = NavigationStack {
            ForYouOnboardingPreview()
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.98)),
            record: false
        )
    }

    // MARK: - Empty State

    func testForYouViewEmpty() {
        let view = NavigationStack {
            ForYouEmptyPreview()
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.98)),
            record: false
        )
    }

    // MARK: - Error State

    func testForYouViewError() {
        let view = NavigationStack {
            ForYouErrorPreview()
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.98)),
            record: false
        )
    }

    // MARK: - Populated State

    func testForYouViewPopulated() {
        let view = NavigationStack {
            ForYouPopulatedPreview()
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.5, on: .image(on: iPhoneAirConfig, precision: 0.95)),
            record: false
        )
    }
}

// MARK: - Preview Helpers for State Testing

private struct ForYouOnboardingPreview: View {
    var body: some View {
        ZStack {
            LinearGradient.subtleBackground
                .ignoresSafeArea()

            GlassCard(style: .regular, shadowStyle: .elevated, padding: Spacing.xl) {
                VStack(spacing: Spacing.lg) {
                    ZStack {
                        Circle()
                            .fill(Color.Accent.gradient)
                            .frame(width: 100, height: 100)

                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: IconSize.xxl))
                            .foregroundStyle(.white)
                    }
                    .glowEffect(color: Color.Accent.primary, radius: 16)

                    Text("Personalize Your Feed")
                        .font(Typography.displaySmall)

                    Text("Follow topics and sources to see articles tailored to your interests.")
                        .font(Typography.bodyMedium)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button {} label: {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "gearshape.fill")
                            Text("Set Preferences")
                        }
                        .font(Typography.labelLarge)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(Color.Accent.gradient)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Spacing.lg)
        }
        .navigationTitle("For You")
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

private struct ForYouEmptyPreview: View {
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

                    Text("No articles found based on your preferences.")
                        .font(Typography.bodyMedium)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(Spacing.lg)
        }
        .navigationTitle("For You")
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

private struct ForYouErrorPreview: View {
    var body: some View {
        ZStack {
            LinearGradient.subtleBackground
                .ignoresSafeArea()

            GlassCard(style: .thin, shadowStyle: .medium, padding: Spacing.xl) {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: IconSize.xxl))
                        .foregroundStyle(Color.Semantic.warning)

                    Text("Unable to Load Feed")
                        .font(Typography.titleMedium)

                    Text("Network connection failed. Please check your internet and try again.")
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
        .navigationTitle("For You")
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

private struct ForYouPopulatedPreview: View {
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
                title: "Climate Summit Reaches Historic Agreement",
                description: "World leaders commit to ambitious carbon reduction targets",
                source: ArticleSource(id: "reuters", name: "Reuters"),
                url: "https://example.com/2",
                imageURL: "https://picsum.photos/400/301",
                publishedAt: fixedDate,
                category: .world
            )),
            ArticleViewItem(from: Article(
                id: "3",
                title: "New Study Links Exercise to Improved Mental Health",
                description: "Research shows regular physical activity reduces anxiety symptoms",
                source: ArticleSource(id: "bbc", name: "BBC Health"),
                url: "https://example.com/3",
                imageURL: "https://picsum.photos/400/302",
                publishedAt: fixedDate,
                category: .health
            )),
        ]
    }

    private var followedTopics: [NewsCategory] {
        [.technology, .world, .health]
    }

    var body: some View {
        ZStack {
            LinearGradient.subtleBackground
                .ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    Section {
                        LazyVStack(spacing: Spacing.sm) {
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
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Spacing.sm) {
                                ForEach(followedTopics, id: \.self) { topic in
                                    GlassTopicChip(
                                        topic: topic.displayName,
                                        isSelected: true,
                                        color: topic.color
                                    ) {}
                                }
                            }
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                        }
                        .background(.ultraThinMaterial)
                    }
                }
            }
        }
        .navigationTitle("For You")
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}
