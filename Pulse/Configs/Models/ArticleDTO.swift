import Foundation

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
        var publishedDate = Self.dateFormatterWithFractional.date(from: publishedAt)
        if publishedDate == nil {
            publishedDate = Self.dateFormatterBasic.date(from: publishedAt)
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

    private static let dateFormatterWithFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let dateFormatterBasic: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}

struct SourceDTO: Codable {
    let id: String?
    let name: String
}
