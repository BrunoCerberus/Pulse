import Foundation

// MARK: - Edge Functions Response Models

/// Article data from Supabase Edge Functions API with flattened structure.
///
/// The Edge Functions return a flat response format with source and category
/// fields directly on the article object (not nested).
///
/// Example response:
/// ```json
/// {
///   "id": "uuid",
///   "title": "Article title",
///   "url": "https://...",
///   "image_url": "https://...",
///   "published_at": "2026-01-22T05:01:00+00:00",
///   "source_name": "The Verge",
///   "source_slug": "the-verge",
///   "category_name": "Technology",
///   "category_slug": "technology"
/// }
/// ```
struct SupabaseArticle: Codable {
    let id: String
    let title: String
    let summary: String?
    let content: String?
    let url: String
    let imageUrl: String?
    let publishedAt: String // ISO8601 string from Supabase

    // Flattened source fields (from Edge Functions)
    let sourceName: String?
    let sourceSlug: String?

    // Flattened category fields (from Edge Functions)
    let categoryName: String?
    let categorySlug: String?

    // Media URL - direct audio/video file URL (from RSS enclosure tag)
    // Optional - only present for podcasts/videos if backend provides it
    let mediaUrl: String?

    // No CodingKeys needed - convertFromSnakeCase handles all conversions

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
            let msg = "SupabaseArticle: Failed to parse date '\(publishedAt)' for \(id)"
            Logger.shared.service(msg, level: .warning)
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

        // Derive media type from category slug
        let derivedMediaType: MediaType? = {
            switch categorySlug {
            case "podcasts": return .podcast
            case "videos": return .video
            default: return nil
            }
        }()

        // Use media_url if available (direct audio/video file), otherwise fallback to article url
        // For videos, the url might be a YouTube link which works for embedding
        // For podcasts, we need the media_url to be the actual audio file URL
        let effectiveMediaURL = mediaUrl ?? url

        return Article(
            id: id,
            title: title,
            description: articleDescription,
            content: articleContent,
            author: nil, // Edge Functions don't include author in list view
            source: ArticleSource(id: sourceSlug, name: sourceName ?? "Unknown"),
            url: url,
            imageURL: imageUrl,
            thumbnailURL: imageUrl, // Use same image for thumbnail
            publishedAt: date,
            category: categorySlug.flatMap { NewsCategory(rawValue: $0) },
            mediaType: derivedMediaType,
            mediaURL: effectiveMediaURL,
            mediaDuration: nil,
            mediaMimeType: nil
        )
    }
}

// MARK: - Search Response Model

/// Search result from the dedicated /api-search endpoint.
/// Returns full article data including content for search relevance.
struct SupabaseSearchResult: Codable {
    let id: String
    let title: String
    let summary: String?
    let content: String?
    let url: String
    let imageUrl: String?
    let publishedAt: String

    // Flattened fields (may be present in search results)
    let sourceName: String?
    let sourceSlug: String?
    let categoryName: String?
    let categorySlug: String?

    // Media URL - direct audio/video file URL (optional)
    let mediaUrl: String?

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
        let date: Date
        if let parsed = Self.iso8601Formatter.date(from: publishedAt) {
            date = parsed
        } else if let parsed = Self.iso8601FormatterNoFraction.date(from: publishedAt) {
            date = parsed
        } else {
            date = Date()
        }

        let articleDescription: String?
        let articleContent: String?

        if let fullContent = content, !fullContent.isEmpty {
            articleDescription = summary
            articleContent = fullContent
        } else if let summaryText = summary, !summaryText.isEmpty {
            articleDescription = nil
            articleContent = summaryText
        } else {
            articleDescription = nil
            articleContent = nil
        }

        // Derive media type from category slug
        let derivedMediaType: MediaType? = {
            switch categorySlug {
            case "podcasts": return .podcast
            case "videos": return .video
            default: return nil
            }
        }()

        let effectiveMediaURL = mediaUrl ?? url

        return Article(
            id: id,
            title: title,
            description: articleDescription,
            content: articleContent,
            author: nil,
            source: ArticleSource(id: sourceSlug, name: sourceName ?? "Unknown"),
            url: url,
            imageURL: imageUrl,
            thumbnailURL: imageUrl,
            publishedAt: date,
            category: categorySlug.flatMap { NewsCategory(rawValue: $0) },
            mediaType: derivedMediaType,
            mediaURL: effectiveMediaURL,
            mediaDuration: nil,
            mediaMimeType: nil
        )
    }
}

// MARK: - Category Response Model

/// Category data from /api-categories endpoint
struct SupabaseCategory: Codable {
    let id: String
    let name: String
    let slug: String
}

// MARK: - Source Response Model

/// Source data from /api-sources endpoint
struct SupabaseSource: Codable {
    let id: String
    let name: String
    let slug: String
    let websiteUrl: String?
    let logoUrl: String?
    let categoryId: String?
    let isActive: Bool?
}
