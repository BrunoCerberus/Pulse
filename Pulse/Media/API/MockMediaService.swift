import Combine
import Foundation

/// Mock implementation of `MediaService` for testing and previews.
///
/// Returns static sample media data for UI development and testing.
final class MockMediaService: MediaService {
    /// Artificial delay to simulate network latency (in seconds).
    var simulatedDelay: TimeInterval = 0.5

    /// Whether to simulate an error response.
    var shouldFail = false

    func fetchMedia(type: MediaType?, language _: String, page: Int) -> AnyPublisher<[Article], Error> {
        if shouldFail {
            return Fail(error: URLError(.notConnectedToInternet))
                .delay(for: .seconds(simulatedDelay), scheduler: DispatchQueue.main)
                .eraseToAnyPublisher()
        }

        let media = Self.sampleMedia.filter { article in
            guard let filterType = type else { return true }
            return article.mediaType == filterType
        }

        // Simulate pagination
        let pageSize = 20
        let startIndex = (page - 1) * pageSize
        let endIndex = min(startIndex + pageSize, media.count)

        guard startIndex < media.count else {
            return Just([])
                .setFailureType(to: Error.self)
                .delay(for: .seconds(simulatedDelay), scheduler: DispatchQueue.main)
                .eraseToAnyPublisher()
        }

        let pageItems = Array(media[startIndex ..< endIndex])
        return Just(pageItems)
            .setFailureType(to: Error.self)
            .delay(for: .seconds(simulatedDelay), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func fetchFeaturedMedia(type: MediaType?, language _: String) -> AnyPublisher<[Article], Error> {
        if shouldFail {
            return Fail(error: URLError(.notConnectedToInternet))
                .delay(for: .seconds(simulatedDelay), scheduler: DispatchQueue.main)
                .eraseToAnyPublisher()
        }

        let featured = Self.sampleMedia.filter { article in
            guard let filterType = type else { return true }
            return article.mediaType == filterType
        }.prefix(5)

        return Just(Array(featured))
            .setFailureType(to: Error.self)
            .delay(for: .seconds(simulatedDelay), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Sample Data

    static let sampleMedia: [Article] = [
        // Videos
        Article(
            id: "video-1",
            title: "iPhone 16 Pro Max Review: The Best iPhone Yet?",
            description: "A comprehensive look at Apple's latest flagship smartphone.",
            content: nil,
            author: "MKBHD",
            source: ArticleSource(id: "mkbhd", name: "MKBHD"),
            url: "https://youtube.com/watch?v=video1",
            imageURL: "https://i.ytimg.com/vi/video1/maxresdefault.jpg",
            thumbnailURL: "https://i.ytimg.com/vi/video1/mqdefault.jpg",
            publishedAt: Date().addingTimeInterval(-3600),
            category: .technology,
            mediaType: .video,
            mediaURL: "https://youtube.com/watch?v=video1",
            mediaDuration: 1245,
            mediaMimeType: "video/youtube"
        ),
        Article(
            id: "video-2",
            title: "The Science of Black Holes Explained",
            description: "What happens when you fall into a black hole?",
            content: nil,
            author: "Veritasium",
            source: ArticleSource(id: "veritasium", name: "Veritasium"),
            url: "https://youtube.com/watch?v=video2",
            imageURL: "https://i.ytimg.com/vi/video2/maxresdefault.jpg",
            thumbnailURL: "https://i.ytimg.com/vi/video2/mqdefault.jpg",
            publishedAt: Date().addingTimeInterval(-7200),
            category: .science,
            mediaType: .video,
            mediaURL: "https://youtube.com/watch?v=video2",
            mediaDuration: 960,
            mediaMimeType: "video/youtube"
        ),
        Article(
            id: "video-3",
            title: "100 Seconds of Kubernetes",
            description: "Learn Kubernetes in under 2 minutes.",
            content: nil,
            author: "Fireship",
            source: ArticleSource(id: "fireship", name: "Fireship"),
            url: "https://youtube.com/watch?v=video3",
            imageURL: "https://i.ytimg.com/vi/video3/maxresdefault.jpg",
            thumbnailURL: "https://i.ytimg.com/vi/video3/mqdefault.jpg",
            publishedAt: Date().addingTimeInterval(-10800),
            category: .technology,
            mediaType: .video,
            mediaURL: "https://youtube.com/watch?v=video3",
            mediaDuration: 100,
            mediaMimeType: "video/youtube"
        ),

        // Podcasts
        Article(
            id: "podcast-1",
            title: "The Daily: What's Next for AI Regulation",
            description: "A look at the global push to regulate artificial intelligence.",
            content: nil,
            author: "Michael Barbaro",
            source: ArticleSource(id: "the-daily", name: "The Daily"),
            url: "https://podcasts.apple.com/podcast1",
            imageURL: "https://is1-ssl.mzstatic.com/image/thumb/daily.jpg",
            thumbnailURL: "https://is1-ssl.mzstatic.com/image/thumb/daily_small.jpg",
            publishedAt: Date().addingTimeInterval(-1800),
            category: .world,
            mediaType: .podcast,
            mediaURL: "https://feeds.simplecast.com/audio1.mp3",
            mediaDuration: 1823,
            mediaMimeType: "audio/mpeg"
        ),
        Article(
            id: "podcast-2",
            title: "Huberman Lab: The Science of Sleep",
            description: "Dr. Andrew Huberman discusses the neuroscience of sleep.",
            content: nil,
            author: "Andrew Huberman",
            source: ArticleSource(id: "huberman-lab", name: "Huberman Lab"),
            url: "https://hubermanlab.com/episode2",
            imageURL: "https://hubermanlab.com/images/huberman.jpg",
            thumbnailURL: "https://hubermanlab.com/images/huberman_small.jpg",
            publishedAt: Date().addingTimeInterval(-86400),
            category: .health,
            mediaType: .podcast,
            mediaURL: "https://feeds.megaphone.fm/huberman.mp3",
            mediaDuration: 7200,
            mediaMimeType: "audio/mpeg"
        ),
        Article(
            id: "podcast-3",
            title: "ATP: Apple's Vision for 2025",
            description: "Marco, Casey, and John discuss Apple's roadmap.",
            content: nil,
            author: "ATP",
            source: ArticleSource(id: "atp", name: "Accidental Tech Podcast"),
            url: "https://atp.fm/episode3",
            imageURL: "https://atp.fm/images/atp.jpg",
            thumbnailURL: "https://atp.fm/images/atp_small.jpg",
            publishedAt: Date().addingTimeInterval(-172_800),
            category: .technology,
            mediaType: .podcast,
            mediaURL: "https://traffic.libsyn.com/atp.mp3",
            mediaDuration: 5400,
            mediaMimeType: "audio/mpeg"
        ),
        Article(
            id: "podcast-4",
            title: "Darknet Diaries: The SolarWinds Hack",
            description: "The inside story of one of the largest cyber attacks.",
            content: nil,
            author: "Jack Rhysider",
            source: ArticleSource(id: "darknet-diaries", name: "Darknet Diaries"),
            url: "https://darknetdiaries.com/episode4",
            imageURL: "https://darknetdiaries.com/images/cover.jpg",
            thumbnailURL: "https://darknetdiaries.com/images/cover_small.jpg",
            publishedAt: Date().addingTimeInterval(-259_200),
            category: .technology,
            mediaType: .podcast,
            mediaURL: "https://feeds.megaphone.fm/darknet.mp3",
            mediaDuration: 4200,
            mediaMimeType: "audio/mpeg"
        ),
    ]
}
