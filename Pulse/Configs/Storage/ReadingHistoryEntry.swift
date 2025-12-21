import Foundation
import SwiftData

@Model
final class ReadingHistoryEntry {
    @Attribute(.unique) var articleID: String
    var title: String
    var articleDescription: String?
    var sourceName: String
    var sourceID: String?
    var url: String
    var imageURL: String?
    var publishedAt: Date
    var readAt: Date
    var category: String?

    init(from article: Article) {
        articleID = article.id
        title = article.title
        articleDescription = article.description
        sourceName = article.source.name
        sourceID = article.source.id
        url = article.url
        imageURL = article.imageURL
        publishedAt = article.publishedAt
        readAt = Date()
        category = article.category?.rawValue
    }

    func toArticle() -> Article {
        Article(
            id: articleID,
            title: title,
            description: articleDescription,
            content: nil,
            author: nil,
            source: ArticleSource(id: sourceID, name: sourceName),
            url: url,
            imageURL: imageURL,
            publishedAt: publishedAt,
            category: category.flatMap { NewsCategory(rawValue: $0) }
        )
    }
}
