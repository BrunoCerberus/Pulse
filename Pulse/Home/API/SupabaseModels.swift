import Foundation

// MARK: - Supabase Response Models

/// Article data from Supabase REST API with embedded relations.
/// Note: Uses snake_case property names since EntropyCore's jsonDecoder uses convertFromSnakeCase
struct SupabaseArticle: Codable {
    let id: String
    let title: String
    let summary: String?
    let content: String?
    let url: String
    let imageUrl: String?
    let thumbnailUrl: String?
    let author: String?
    let publishedAt: String // ISO8601 string from Supabase
    let sources: SupabaseSource?
    let categories: SupabaseCategory?

    // No CodingKeys needed - convertFromSnakeCase handles image_url -> imageUrl, etc.

    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let iso8601FormatterNoFraction: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    func toArticle() -> Article {
        // Parse ISO8601 date string
        let date: Date
        if let parsed = Self.iso8601Formatter.date(from: publishedAt) {
            date = parsed
        } else if let parsed = Self.iso8601FormatterNoFraction.date(from: publishedAt) {
            date = parsed
        } else {
            Logger.shared.service("SupabaseArticle: Failed to parse date '\(publishedAt)' for article \(id)", level: .warning)
            date = Date()
        }

        // Handle content/description mapping for RSS feeds:
        // - If content exists, use summary as description (short preview) and content as body
        // - If only summary exists, use it as full content (no description to avoid duplication)
        let articleDescription: String?
        let articleContent: String?

        if let fullContent = content, !fullContent.isEmpty {
            // Backend has both fields populated
            articleDescription = summary
            articleContent = fullContent
        } else if let summaryText = summary, !summaryText.isEmpty {
            // RSS feed only has summary - use it as content, no description to avoid duplication
            articleDescription = nil
            articleContent = summaryText
        } else {
            articleDescription = nil
            articleContent = nil
        }

        // Handle image URLs: RSS feeds often only have one image
        // Use whatever is available, preferring full-size image_url for hero images
        // Don't fallback to full-res for thumbnail to avoid loading large images in list views
        let fullImageURL = imageUrl ?? thumbnailUrl
        let thumbURL = thumbnailUrl

        return Article(
            id: id,
            title: title,
            description: articleDescription,
            content: articleContent,
            author: author,
            source: ArticleSource(id: sources?.slug, name: sources?.name ?? "Unknown"),
            url: url,
            imageURL: fullImageURL,
            thumbnailURL: thumbURL,
            publishedAt: date,
            category: categories.flatMap { NewsCategory(rawValue: $0.slug) }
        )
    }
}

/// Source data - only decode fields we need, ignore extra fields
struct SupabaseSource: Codable {
    let id: String
    let name: String
    let slug: String
    let logoUrl: String?
    let websiteUrl: String?
    // Extra fields from API are ignored automatically
}

/// Category data - only decode fields we need
struct SupabaseCategory: Codable {
    let id: String
    let name: String
    let slug: String
    // Extra fields like created_at, display_order are ignored
}
