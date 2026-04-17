import Foundation
import SwiftData

/// SwiftData model for persisting reading history.
///
/// Every property has a default value so the model is compatible with
/// CloudKit sync via `NSPersistentCloudKitContainer`. Duplicate prevention is
/// enforced at the service layer (`LiveStorageService.markArticleAsRead`
/// upserts by `articleID`).
@Model
final class ReadArticle {
    /// Identifier for the article (Guardian content ID or URL).
    var articleID: String = ""
    /// Article headline text.
    var title: String = ""
    /// Short description or trail text for the article.
    var articleDescription: String?
    /// Full article body content (HTML or plain text).
    var content: String?
    /// Article author or byline.
    var author: String?
    /// Display name of the article's source publication.
    var sourceName: String = ""
    /// Machine identifier for the source (e.g., "guardian", "bbc-news").
    var sourceID: String?
    /// Original web URL for the article.
    var url: String = ""
    /// URL for the article's hero/thumbnail image.
    var imageURL: String?
    /// Original publication timestamp.
    var publishedAt: Date = Date.distantPast
    /// Timestamp when the user read this article.
    var readAt: Date = Date()
    /// News category as raw string value (stored for SwiftData compatibility).
    var category: String?

    /// Creates a read article entry from a domain Article model.
    /// - Parameter article: The article that was read.
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
        readAt = .now
        category = article.category?.rawValue
    }

    /// Converts this persisted model back to a domain Article.
    /// - Returns: An Article instance reconstructed from stored data.
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
