import Foundation
import SwiftData

@Model
final class CollectionArticleModel {
    @Attribute(.unique) var compositeKey: String
    var collectionID: String
    var articleID: String
    var title: String
    var articleDescription: String?
    var content: String?
    var author: String?
    var sourceName: String
    var sourceID: String?
    var url: String
    var imageURL: String?
    var publishedAt: Date
    var addedAt: Date
    var orderIndex: Int
    var category: String?

    init(collectionID: String, article: Article, orderIndex: Int) {
        compositeKey = "\(collectionID)_\(article.id)"
        self.collectionID = collectionID
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
        addedAt = Date()
        self.orderIndex = orderIndex
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
