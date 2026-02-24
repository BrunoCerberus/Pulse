import EntropyCore
@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class MediaDetailViewSnapshotTests: XCTestCase {
    private var serviceLocator: ServiceLocator!

    private let iPhoneAirConfig = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 393, height: 852),
        traits: UITraitCollection(userInterfaceStyle: .dark)
    )

    private let iPhoneAirLightConfig = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 393, height: 852),
        traits: UITraitCollection(userInterfaceStyle: .light)
    )

    private let fixedDate = Date(timeIntervalSince1970: 1_672_531_200)

    private var videoArticle: Article {
        Article(
            id: "snapshot-video-1",
            title: "SwiftUI 6.0: What's New for Developers",
            description: "A comprehensive look at the new features in SwiftUI 6.0 including the new navigation APIs and enhanced animations.",
            content: nil,
            author: "WWDC",
            source: ArticleSource(id: "apple", name: "Apple Developer"),
            url: "https://www.youtube.com/watch?v=example",
            imageURL: "https://img.youtube.com/vi/example/maxresdefault.jpg",
            publishedAt: fixedDate,
            category: .technology,
            mediaType: .video,
            mediaURL: "https://www.youtube.com/watch?v=example",
            mediaDuration: 1845,
            mediaMimeType: "video/mp4"
        )
    }

    private var podcastArticle: Article {
        Article(
            id: "snapshot-podcast-1",
            title: "The Daily: Tech News Roundup",
            description: "Today's top technology stories and what they mean for you in this comprehensive podcast episode.",
            content: nil,
            author: "Michael Barbaro",
            source: ArticleSource(id: "nyt", name: "The New York Times"),
            url: "https://example.com/podcast",
            imageURL: nil,
            publishedAt: fixedDate,
            category: .technology,
            mediaType: .podcast,
            mediaURL: "https://audio.example.com/podcast.mp3",
            mediaDuration: 2700,
            mediaMimeType: "audio/mpeg"
        )
    }

    private var longTitleArticle: Article {
        Article(
            id: "snapshot-long",
            title: "This Is An Extremely Long Video Title That Should Test How The UI Handles Text Truncation And Line Limits In The Media Detail View Component",
            description: "A brief description that accompanies this video with the very long title to see how both elements render together.",
            content: nil,
            author: "Long Form Creator",
            source: ArticleSource(id: "vimeo", name: "Vimeo"),
            url: "https://www.youtube.com/watch?v=verylongvideo",
            imageURL: nil,
            publishedAt: fixedDate,
            category: .entertainment,
            mediaType: .video,
            mediaURL: "https://www.youtube.com/watch?v=verylongvideo",
            mediaDuration: 7200,
            mediaMimeType: "video/mp4"
        )
    }

    override func setUp() {
        super.setUp()
        serviceLocator = ServiceLocator()
        serviceLocator.register(MediaService.self, instance: MockMediaService())
        serviceLocator.register(StorageService.self, instance: MockStorageService())
    }

    // MARK: - MediaDetailView Tests

    func testMediaDetailViewVideo() {
        let view = NavigationStack {
            MediaDetailView(article: videoArticle, serviceLocator: serviceLocator)
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: iPhoneAirConfig),
            record: true
        )
    }

    func testMediaDetailViewVideoLightMode() {
        let view = NavigationStack {
            MediaDetailView(article: videoArticle, serviceLocator: serviceLocator)
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: iPhoneAirLightConfig),
            record: true
        )
    }

    func testMediaDetailViewPodcast() {
        let view = NavigationStack {
            MediaDetailView(article: podcastArticle, serviceLocator: serviceLocator)
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: iPhoneAirConfig),
            record: true
        )
    }

    func testMediaDetailViewLongTitle() {
        let view = NavigationStack {
            MediaDetailView(article: longTitleArticle, serviceLocator: serviceLocator)
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: iPhoneAirConfig),
            record: true
        )
    }

    // MARK: - YouTubeThumbnailView Tests

    func testYouTubeThumbnailView() {
        let view = YouTubeThumbnailView(
            urlString: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
            articleImageURL: nil
        )
        .frame(width: 375)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: iPhoneAirConfig),
            record: false
        )
    }

    func testYouTubeThumbnailViewLightMode() {
        let view = YouTubeThumbnailView(
            urlString: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
            articleImageURL: nil
        )
        .frame(width: 375)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: iPhoneAirLightConfig),
            record: false
        )
    }

    func testYouTubeThumbnailViewWithArticleImage() {
        let view = YouTubeThumbnailView(
            urlString: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
            articleImageURL: "https://picsum.photos/800/450"
        )
        .frame(width: 375)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: iPhoneAirConfig),
            record: true
        )
    }

    func testYouTubeThumbnailViewShortURL() {
        let view = YouTubeThumbnailView(
            urlString: "https://youtu.be/dQw4w9WgXcQ",
            articleImageURL: nil
        )
        .frame(width: 375)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: iPhoneAirConfig),
            record: false
        )
    }
}
