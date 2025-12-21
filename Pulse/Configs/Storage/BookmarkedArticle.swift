import Foundation
import SwiftData

@Model
final class BookmarkedArticle {
    @Attribute(.unique) var articleID: String
    var title: String
    var articleDescription: String?
    var content: String?
    var author: String?
    var sourceName: String
    var sourceID: String?
    var url: String
    var imageURL: String?
    var publishedAt: Date
    var savedAt: Date
    var category: String?

    init(from article: Article) {
        articleID = article.id
        title = article.title
        articleDescription = article.description
        content = article.content
        author = article.author
        sourceName = article.source.name
        sourceID = article.source.id
        url = article.url
        imageURL = article.imageURL
        publishedAt = article.publishedAt
        savedAt = Date()
        category = article.category?.rawValue
    }

    func toArticle() -> Article {
        Article(
            id: articleID,
            title: title,
            description: articleDescription,
            content: content,
            author: author,
            source: ArticleSource(id: sourceID, name: sourceName),
            url: url,
            imageURL: imageURL,
            publishedAt: publishedAt,
            category: category.flatMap { NewsCategory(rawValue: $0) }
        )
    }
}
