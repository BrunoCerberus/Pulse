import Foundation

struct Article: Identifiable, Equatable, Codable, Hashable {
    let id: String
    let title: String
    let description: String?
    let content: String?
    let author: String?
    let source: ArticleSource
    let url: String
    let imageURL: String?
    let thumbnailURL: String?
    let publishedAt: Date
    let category: NewsCategory?

    // MARK: - Media Properties

    /// Type of media content (nil for regular articles).
    let mediaType: MediaType?

    /// Direct URL to the media content (audio/video file or YouTube URL).
    let mediaURL: String?

    /// Duration of media in seconds.
    let mediaDuration: Int?

    /// MIME type of the media content (e.g., "audio/mpeg", "video/mp4").
    let mediaMimeType: String?

    init(
        id: String = UUID().uuidString,
        title: String,
        description: String? = nil,
        content: String? = nil,
        author: String? = nil,
        source: ArticleSource,
        url: String,
        imageURL: String? = nil,
        thumbnailURL: String? = nil,
        publishedAt: Date,
        category: NewsCategory? = nil,
        mediaType: MediaType? = nil,
        mediaURL: String? = nil,
        mediaDuration: Int? = nil,
        mediaMimeType: String? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.content = content
        self.author = author
        self.source = source
        self.url = url
        self.imageURL = imageURL
        self.thumbnailURL = thumbnailURL
        self.publishedAt = publishedAt
        self.category = category
        self.mediaType = mediaType
        self.mediaURL = mediaURL
        self.mediaDuration = mediaDuration
        self.mediaMimeType = mediaMimeType
    }

    /// Returns the best available image URL for list/cell display (prefers thumbnail)
    var displayImageURL: String? {
        thumbnailURL ?? imageURL
    }

    /// Returns the best available image URL for detail/hero display (prefers full resolution)
    var heroImageURL: String? {
        imageURL ?? thumbnailURL
    }

    var formattedDate: String {
        Self.relativeFormatter.localizedString(for: publishedAt, relativeTo: Date())
    }

    /// Formatted duration string (e.g., "1:23:45" or "23:45").
    var formattedDuration: String? {
        guard let duration = mediaDuration, duration > 0 else { return nil }

        let hours = duration / 3600
        let minutes = (duration % 3600) / 60
        let seconds = duration % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    /// Whether this article is a media item (video or podcast).
    var isMedia: Bool {
        mediaType != nil
    }

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()
}

struct ArticleSource: Equatable, Codable, Hashable {
    let id: String?
    let name: String
}
