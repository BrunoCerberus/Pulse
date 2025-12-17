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
        self.publishedAt = publishedAt
        self.category = category
    }

    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: publishedAt, relativeTo: Date())
    }
}

struct ArticleSource: Equatable, Codable, Hashable {
    let id: String?
    let name: String
}
