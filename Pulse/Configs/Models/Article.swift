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

    /// Returns the best available image URL for list/cell display (prefers thumbnail, optimized for ~300px)
    var displayImageURL: String? {
        guard let url = thumbnailURL ?? imageURL else { return nil }
        return Self.optimizeImageURL(url, targetWidth: 300)
    }

    /// Returns the best available image URL for detail/hero display (prefers full resolution, optimized for ~1200px)
    var heroImageURL: String? {
        guard let url = imageURL ?? thumbnailURL else { return nil }
        return Self.optimizeImageURL(url, targetWidth: 1200)
    }

    /// Optimizes image URLs from known providers to request the desired resolution
    /// Currently supports: Guardian (i.guim.co.uk)
    private static func optimizeImageURL(_ urlString: String, targetWidth: Int) -> String {
        // Guardian image optimization: change width parameter
        // Format: https://i.guim.co.uk/img/media/.../image.jpg?width=140&quality=85&...
        if urlString.contains("i.guim.co.uk") {
            // Replace width parameter with target width
            var optimized = urlString
            if let range = optimized.range(of: "width=\\d+", options: .regularExpression) {
                optimized = optimized.replacingCharacters(in: range, with: "width=\(targetWidth)")
            }
            // Also increase quality for hero images
            if targetWidth >= 800, let range = optimized.range(of: "quality=\\d+", options: .regularExpression) {
                optimized = optimized.replacingCharacters(in: range, with: "quality=95")
            }
            return optimized
        }

        return urlString
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
