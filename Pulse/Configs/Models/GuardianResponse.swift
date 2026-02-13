import Foundation

/// Root response wrapper for Guardian API search/content endpoints.
///
/// The Guardian API wraps all responses in a `response` object containing
/// pagination metadata and the actual results array.
struct GuardianResponse: Codable {
    /// The actual response content with pagination and results.
    let response: GuardianResponseContent
}

/// Content wrapper containing pagination metadata and article results.
struct GuardianResponseContent: Codable {
    /// API response status (typically "ok").
    let status: String
    /// Total number of results matching the query.
    let total: Int
    /// Index of first result in this page (1-based).
    let startIndex: Int
    /// Number of results per page.
    let pageSize: Int
    /// Current page number (1-based).
    let currentPage: Int
    /// Total number of pages available.
    let pages: Int
    /// Array of article DTOs for this page.
    let results: [GuardianArticleDTO]
}

/// Response structure for single article endpoint (`/content/{id}`).
///
/// Used when fetching a specific article by its Guardian content ID,
/// such as when handling deeplinks to individual articles.
struct GuardianSingleArticleResponse: Codable {
    /// The response content containing the single article.
    let response: GuardianSingleArticleContent
}

/// Content wrapper for single article responses.
struct GuardianSingleArticleContent: Codable {
    /// API response status (typically "ok").
    let status: String
    /// The requested article data.
    let content: GuardianArticleDTO
}

/// Data Transfer Object for Guardian API article data.
///
/// Maps to the article structure returned by Guardian's Content API.
/// The `fields` object contains optional extended data requested via
/// the `show-fields` query parameter (thumbnail, body, byline, etc.).
struct GuardianArticleDTO: Codable {
    /// Guardian content ID (e.g., "world/2024/jan/01/article-slug").
    let id: String
    /// Content type (typically "article", "liveblog", or "video").
    let type: String
    /// Machine identifier for the section (e.g., "world", "technology").
    let sectionId: String
    /// Human-readable section name (e.g., "World news", "Technology").
    let sectionName: String
    /// ISO 8601 publication timestamp.
    let webPublicationDate: String
    /// Article headline.
    let webTitle: String
    /// Public web URL for the article.
    let webUrl: String
    /// Internal Guardian API URL for this content.
    let apiUrl: String
    /// Extended fields (requires `show-fields` parameter in request).
    let fields: GuardianFieldsDTO?

    /// Converts this DTO to a domain Article model.
    /// - Parameter category: Optional category override. If nil, category is inferred from sectionId.
    /// - Returns: An Article if date parsing succeeds, nil otherwise.
    func toArticle(category: NewsCategory? = nil) -> Article? {
        var publishedDate = Self.dateFormatterWithFractional.date(from: webPublicationDate)
        if publishedDate == nil {
            publishedDate = Self.dateFormatterBasic.date(from: webPublicationDate)
        }

        guard let date = publishedDate else { return nil }

        let resolvedCategory = category ?? NewsCategory.fromGuardianSection(sectionId)

        return Article(
            id: id,
            title: webTitle,
            description: fields?.trailText,
            content: fields?.body,
            author: fields?.byline,
            source: ArticleSource(id: "guardian", name: sectionName),
            url: webUrl,
            imageURL: fields?.thumbnail,
            publishedAt: date,
            category: resolvedCategory
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

/// Extended fields from Guardian API (requested via `show-fields` parameter).
///
/// These fields provide additional article data beyond the basic metadata.
/// Request specific fields with `show-fields=thumbnail,trailText,body,byline`.
struct GuardianFieldsDTO: Codable {
    /// URL for the article's thumbnail image.
    let thumbnail: String?
    /// Short description/standfirst text for article previews.
    let trailText: String?
    /// Full article body content (HTML).
    let body: String?
    /// Article author attribution.
    let byline: String?
}
