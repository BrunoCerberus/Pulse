import Foundation

/// Data Transfer Object for articles from NewsAPI.org responses.
///
/// This struct maps directly to the JSON structure returned by NewsAPI.org's
/// `/everything` and `/top-headlines` endpoints. The `toArticle()` method
/// converts this DTO into the domain `Article` model used throughout the app.
struct ArticleDTO: Codable {
    /// Source information (id and name).
    let source: SourceDTO
    /// Article author or byline (may be nil for wire stories).
    let author: String?
    /// Article headline.
    let title: String
    /// Short description or lead paragraph.
    let description: String?
    /// Original article URL.
    let url: String
    /// Hero image URL (named `urlToImage` in NewsAPI response).
    let urlToImage: String?
    /// ISO 8601 publication timestamp string.
    let publishedAt: String
    /// Truncated article content (NewsAPI limits to ~200 chars on free tier).
    let content: String?

    /// Converts this DTO to a domain Article model.
    /// - Parameter category: Optional category to assign (NewsAPI doesn't provide categories).
    /// - Returns: An Article if date parsing succeeds, nil otherwise.
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

    /// ISO 8601 formatter with fractional seconds support.
    private static let dateFormatterWithFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    /// ISO 8601 formatter without fractional seconds (fallback).
    private static let dateFormatterBasic: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}

/// Source information from NewsAPI.org article responses.
struct SourceDTO: Codable {
    /// Machine identifier for the source (may be nil for some sources).
    let id: String?
    /// Human-readable source name (e.g., "BBC News", "TechCrunch").
    let name: String
}
