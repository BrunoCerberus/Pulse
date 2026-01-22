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
        category: NewsCategory? = nil
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
