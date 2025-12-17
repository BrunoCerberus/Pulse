import Foundation

struct NewsResponse: Codable {
    let status: String
    let totalResults: Int
    let articles: [ArticleDTO]
}

struct ArticleDTO: Codable {
    let source: SourceDTO
    let author: String?
    let title: String
    let description: String?
    let url: String
    let urlToImage: String?
    let publishedAt: String
    let content: String?

    func toArticle(category: NewsCategory? = nil) -> Article? {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        var publishedDate = dateFormatter.date(from: publishedAt)
        if publishedDate == nil {
            dateFormatter.formatOptions = [.withInternetDateTime]
            publishedDate = dateFormatter.date(from: publishedAt)
        }

        guard let date = publishedDate else { return nil }

        return Article(
            id: url,
            title: title,
            description: description,
            content: content,
            author: author,
            source: ArticleSource(id: source.id, name: source.name),
            url: url,
            imageURL: urlToImage,
            publishedAt: date,
            category: category
        )
    }
}

struct SourceDTO: Codable {
    let id: String?
    let name: String
}
