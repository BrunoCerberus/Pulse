import EntropyCore
@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class MediaViewSnapshotTests: XCTestCase {
    private var serviceLocator: ServiceLocator!

    /// Custom device config matching CI's iPhone Air simulator (forced dark mode)
    private let iPhoneAirConfig = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 393, height: 852),
        traits: UITraitCollection(userInterfaceStyle: .dark)
    )

    /// Light mode config for additional coverage
    private let iPhoneAirLightConfig = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 393, height: 852),
        traits: UITraitCollection(userInterfaceStyle: .light)
    )

    /// Fixed date for snapshot stability (Jan 1, 2023 - consistent relative time)
    private let fixedDate = Date(timeIntervalSince1970: 1_672_531_200)

    // MARK: - Sample Media Items

    private var videoArticle: Article {
        Article(
            id: "snapshot-video-1",
            title: "SwiftUI 6.0: What's New for Developers",
            description: "A comprehensive look at the new features in SwiftUI 6.0",
            content: nil,
            author: "WWDC",
            source: ArticleSource(id: "apple", name: "Apple Developer"),
            url: "https://example.com/video/test123",
            imageURL: nil,
            thumbnailURL: nil,
            publishedAt: fixedDate,
            category: .technology,
            mediaType: .video,
            mediaURL: "https://example.com/video/test123",
            mediaDuration: 1845,
            mediaMimeType: "video/mp4"
        )
    }

    private var podcastArticle: Article {
        Article(
            id: "snapshot-podcast-1",
            title: "The Daily: Tech News Roundup",
            description: "Today's top technology stories and what they mean for you",
            content: nil,
            author: "Michael Barbaro",
            source: ArticleSource(id: "nyt", name: "The New York Times"),
            url: "https://podcasts.apple.com/test",
            imageURL: nil,
            thumbnailURL: nil,
            publishedAt: fixedDate,
            category: .technology,
            mediaType: .podcast,
            mediaURL: "https://audio.example.com/podcast.mp3",
            mediaDuration: 2700,
            mediaMimeType: "audio/mpeg"
        )
    }

    private var longTitleVideoArticle: Article {
        Article(
            id: "snapshot-video-long",
            title: "This Is An Extremely Long Video Title That Should Test How The UI Handles Text Truncation And Line Limits In The Media Card View Component",
            description: "A brief description that accompanies this video with the very long title.",
            content: nil,
            author: "Long Form Creator",
            source: ArticleSource(id: "vimeo", name: "Vimeo"),
            url: "https://example.com/video/long",
            imageURL: nil,
            thumbnailURL: nil,
            publishedAt: fixedDate,
            category: .entertainment,
            mediaType: .video,
            mediaURL: "https://example.com/video/long",
            mediaDuration: 7200,
            mediaMimeType: "video/mp4"
        )
    }

    override func setUp() {
        super.setUp()
        serviceLocator = ServiceLocator()
        let mockMediaService = MockMediaService()
        mockMediaService.simulatedDelay = 0
        serviceLocator.register(MediaService.self, instance: mockMediaService)
        serviceLocator.register(StorageService.self, instance: MockStorageService())
    }

    // MARK: - MediaCard Tests

    func testMediaCardVideo() {
        let item = MediaViewItem(from: videoArticle, index: 0)
        let view = MediaCard(
            item: item,
            onTap: {},
            onPlay: {},
            onShare: {}
        )
        .frame(width: 375)
        .padding()

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    func testMediaCardPodcast() {
        let item = MediaViewItem(from: podcastArticle, index: 0)
        let view = MediaCard(
            item: item,
            onTap: {},
            onPlay: {},
            onShare: {}
        )
        .frame(width: 375)
        .padding()

        let controller = UIHostingController(rootView: view)

        // Lower precision (0.97) to account for favicon image loading differences across environments
        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.97)),
            record: false
        )
    }

    func testMediaCardLongTitle() {
        let item = MediaViewItem(from: longTitleVideoArticle, index: 0)
        let view = MediaCard(
            item: item,
            onTap: {},
            onPlay: {},
            onShare: {}
        )
        .frame(width: 375)
        .padding()

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    func testMediaCardLightMode() {
        let item = MediaViewItem(from: videoArticle, index: 0)
        let view = MediaCard(
            item: item,
            onTap: {},
            onPlay: {},
            onShare: {}
        )
        .frame(width: 375)
        .padding()

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirLightConfig, precision: 0.99)),
            record: false
        )
    }

    // MARK: - FeaturedMediaCard Tests

    func testFeaturedMediaCardVideo() {
        let item = MediaViewItem(from: videoArticle, index: 0)
        let view = FeaturedMediaCard(
            item: item,
            onTap: {}
        )
        .frame(width: 375)
        .padding()

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    func testFeaturedMediaCardPodcast() {
        let item = MediaViewItem(from: podcastArticle, index: 0)
        let view = FeaturedMediaCard(
            item: item,
            onTap: {}
        )
        .frame(width: 375)
        .padding()

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    func testFeaturedMediaCardLightMode() {
        let item = MediaViewItem(from: videoArticle, index: 0)
        let view = FeaturedMediaCard(
            item: item,
            onTap: {}
        )
        .frame(width: 375)
        .padding()

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirLightConfig, precision: 0.99)),
            record: false
        )
    }

    // MARK: - MediaSegmentedControl Tests

    func testMediaSegmentedControlAllSelected() {
        let view = MediaSegmentedControlPreview(selectedType: nil)
            .frame(width: 375)
            .padding()

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    func testMediaSegmentedControlVideoSelected() {
        let view = MediaSegmentedControlPreview(selectedType: .video)
            .frame(width: 375)
            .padding()

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    func testMediaSegmentedControlPodcastSelected() {
        let view = MediaSegmentedControlPreview(selectedType: .podcast)
            .frame(width: 375)
            .padding()

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    func testMediaSegmentedControlLightMode() {
        let view = MediaSegmentedControlPreview(selectedType: nil)
            .frame(width: 375)
            .padding()

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: iPhoneAirLightConfig, precision: 0.99)),
            record: false
        )
    }

    // MARK: - Multiple Cards Tests

    func testMultipleMediaCards() {
        let items = [
            MediaViewItem(from: videoArticle, index: 0),
            MediaViewItem(from: podcastArticle, index: 1),
        ]

        let view = VStack(spacing: Spacing.md) {
            ForEach(items) { item in
                MediaCard(
                    item: item,
                    onTap: {},
                    onPlay: {},
                    onShare: {}
                )
            }
        }
        .frame(width: 375)
        .padding()

        let controller = UIHostingController(rootView: view)

        // Lower precision (0.97) to account for favicon image loading differences across environments
        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.97)),
            record: false
        )
    }

    // MARK: - Empty State Tests

    func testMediaEmptyState() {
        let view = NavigationStack {
            MediaEmptyStatePreview()
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    func testMediaEmptyStateLightMode() {
        let view = NavigationStack {
            MediaEmptyStatePreview()
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirLightConfig, precision: 0.99)),
            record: false
        )
    }
}

// MARK: - Preview Helpers

private struct MediaSegmentedControlPreview: View {
    let selectedType: MediaType?

    var body: some View {
        ZStack {
            LinearGradient.subtleBackground
                .ignoresSafeArea()

            MediaSegmentedControl(
                selectedType: selectedType,
                onSelect: { _ in }
            )
        }
    }
}

private struct MediaEmptyStatePreview: View {
    var body: some View {
        ZStack {
            LinearGradient.subtleBackground
                .ignoresSafeArea()

            GlassCard(style: .thin, shadowStyle: .medium, padding: Spacing.xl) {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "play.rectangle.on.rectangle")
                        .font(.system(size: IconSize.xxl))
                        .foregroundStyle(.secondary)

                    Text("No Media Available")
                        .font(Typography.titleMedium)

                    Text("Videos and podcasts will appear here. Pull to refresh.")
                        .font(Typography.bodyMedium)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(Spacing.lg)
        }
        .navigationTitle("Media")
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}
