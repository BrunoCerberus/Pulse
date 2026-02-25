import EntropyCore
@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class AudioPlayerViewSnapshotTests: XCTestCase {
    private let iPhoneAirConfig = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 393, height: 500),
        traits: UITraitCollection(userInterfaceStyle: .dark)
    )

    private let iPhoneAirLightConfig = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 393, height: 500),
        traits: UITraitCollection(userInterfaceStyle: .light)
    )

    private let fixedDate = Date(timeIntervalSince1970: 1_672_531_200)

    private var samplePodcast: Article {
        Article(
            id: "snapshot-podcast-1",
            title: "The Future of AI in Software Development",
            description: "A deep dive into how AI is transforming the way we write code and what it means for developers.",
            content: nil,
            author: "Tech Talk Daily",
            source: ArticleSource(id: "tech", name: "Tech Talk Daily"),
            url: "https://example.com/podcast",
            imageURL: nil,
            publishedAt: fixedDate,
            category: .technology,
            mediaType: .podcast,
            mediaURL: "https://example.com/audio.mp3",
            mediaDuration: 3600,
            mediaMimeType: "audio/mpeg"
        )
    }

    private var longTitlePodcast: Article {
        Article(
            id: "snapshot-podcast-long",
            title: "This Is An Extremely Long Podcast Title That Should Test How The UI Handles Text Truncation And Line Limits In The Audio Player View Component",
            description: "A brief description that accompanies this podcast.",
            content: nil,
            author: "Long Form Podcast",
            source: ArticleSource(id: "podcast", name: "Podcast Channel"),
            url: "https://example.com/long-podcast",
            imageURL: nil,
            publishedAt: fixedDate,
            category: .technology,
            mediaType: .podcast,
            mediaURL: "https://example.com/audio.mp3",
            mediaDuration: 7200,
            mediaMimeType: "audio/mpeg"
        )
    }

    // MARK: - AudioPlayerView Tests

    func testAudioPlayerView() {
        let view = AudioPlayerView(
            article: samplePodcast,
            onProgressUpdate: { _, _ in },
            onDurationLoaded: { _ in },
            onError: { _ in },
            onLoadingChanged: { _ in },
            onPlayStateChanged: { _ in }
        )
        .frame(width: 375)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: iPhoneAirConfig),
            record: false
        )
    }

    func testAudioPlayerViewLightMode() {
        let view = AudioPlayerView(
            article: samplePodcast,
            onProgressUpdate: { _, _ in },
            onDurationLoaded: { _ in },
            onError: { _ in },
            onLoadingChanged: { _ in },
            onPlayStateChanged: { _ in }
        )
        .frame(width: 375)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: iPhoneAirLightConfig),
            record: false
        )
    }

    func testAudioPlayerViewLongTitle() {
        let view = AudioPlayerView(
            article: longTitlePodcast,
            onProgressUpdate: { _, _ in },
            onDurationLoaded: { _ in },
            onError: { _ in },
            onLoadingChanged: { _ in },
            onPlayStateChanged: { _ in }
        )
        .frame(width: 375)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: iPhoneAirConfig),
            record: false
        )
    }

    func testAudioPlayerViewWithImage() {
        let podcastWithImage = Article(
            id: "snapshot-podcast-img",
            title: "Podcast with Artwork",
            description: "A podcast that has an image URL.",
            content: nil,
            author: "Image Podcast",
            source: ArticleSource(id: "img", name: "Image Cast"),
            url: "https://example.com/podcast-img",
            imageURL: "https://picsum.photos/400/400",
            publishedAt: fixedDate,
            category: .technology,
            mediaType: .podcast,
            mediaURL: "https://example.com/audio.mp3",
            mediaDuration: 1800,
            mediaMimeType: "audio/mpeg"
        )

        let view = AudioPlayerView(
            article: podcastWithImage,
            onProgressUpdate: { _, _ in },
            onDurationLoaded: { _ in },
            onError: { _ in },
            onLoadingChanged: { _ in },
            onPlayStateChanged: { _ in }
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
