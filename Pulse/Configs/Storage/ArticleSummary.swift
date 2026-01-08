import Foundation
import SwiftData

@Model
final class ArticleSummary {
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
    var category: String?
    var summary: String
    var generatedAt: Date

    init(from article: Article, summary: String) {
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
        category = article.category?.rawValue
        self.summary = summary
        generatedAt = Date()
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
