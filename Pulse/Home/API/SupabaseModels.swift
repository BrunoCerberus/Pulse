import EntropyCore
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

    // Media fields (for podcasts and videos)
    let mediaType: String? // "podcast", "video", or nil
    let mediaUrl: String? // Direct URL to audio/video file
    let mediaDuration: Int? // Duration in seconds
    let mediaMimeType: String? // "audio/mpeg", "video/mp4", etc.

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
        Article(
            id: id,
            title: title,
            description: descriptionAndContent.description,
            content: descriptionAndContent.content,
            author: nil, // Edge Functions don't include author in list view
            source: ArticleSource(id: sourceSlug, name: sourceName ?? "Unknown"),
            url: url,
            imageURL: imageUrl,
            thumbnailURL: imageUrl, // Use same image for thumbnail
            publishedAt: parsedPublishedAt,
            category: categorySlug.flatMap { NewsCategory(rawValue: $0) },
            mediaType: derivedMediaType,
            mediaURL: mediaUrl ?? url,
            mediaDuration: mediaDuration,
            mediaMimeType: mediaMimeType
        )
    }

    private var parsedPublishedAt: Date {
        if let parsed = Self.iso8601Formatter.date(from: publishedAt) {
            return parsed
        }
        if let parsed = Self.iso8601FormatterNoFraction.date(from: publishedAt) {
            return parsed
        }

        let msg = "SupabaseArticle: Failed to parse date '\(publishedAt)' for \(id)"
        Logger.shared.service(msg, level: .warning)
        return Date()
    }

    private var descriptionAndContent: (description: String?, content: String?) {
        // Content/description mapping for RSS feeds:
        // - If content exists: description = summary (short preview), content = content (full)
        // - If only summary exists: content = summary, description = nil (avoid duplication)
        if let fullContent = content, !fullContent.isEmpty {
            return (summary, fullContent)
        }
        if let summaryText = summary, !summaryText.isEmpty {
            return (nil, summaryText)
        }
        return (nil, nil)
    }

    private var derivedMediaType: MediaType? {
        if let type = mediaType {
            switch type {
            case "podcast": return .podcast
            case "video": return .video
            default: return nil
            }
        }

        // Fallback: derive from category_slug
        switch categorySlug {
        case "podcasts": return .podcast
        case "videos": return .video
        default: return nil
        }
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

    // Media fields (for podcasts and videos)
    let mediaType: String?
    let mediaUrl: String?
    let mediaDuration: Int?
    let mediaMimeType: String?

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
        Article(
            id: id,
            title: title,
            description: descriptionAndContent.description,
            content: descriptionAndContent.content,
            author: nil,
            source: ArticleSource(id: sourceSlug, name: sourceName ?? "Unknown"),
            url: url,
            imageURL: imageUrl,
            thumbnailURL: imageUrl,
            publishedAt: parsedPublishedAt,
            category: categorySlug.flatMap { NewsCategory(rawValue: $0) },
            mediaType: derivedMediaType,
            mediaURL: mediaUrl ?? url,
            mediaDuration: mediaDuration,
            mediaMimeType: mediaMimeType
        )
    }

    private var parsedPublishedAt: Date {
        Self.iso8601Formatter.date(from: publishedAt)
            ?? Self.iso8601FormatterNoFraction.date(from: publishedAt)
            ?? Date()
    }

    private var descriptionAndContent: (description: String?, content: String?) {
        if let fullContent = content, !fullContent.isEmpty {
            return (summary, fullContent)
        }
        if let summaryText = summary, !summaryText.isEmpty {
            return (nil, summaryText)
        }
        return (nil, nil)
    }

    private var derivedMediaType: MediaType? {
        if let type = mediaType {
            switch type {
            case "podcast": return .podcast
            case "video": return .video
            default: return nil
            }
        }
        switch categorySlug {
        case "podcasts": return .podcast
        case "videos": return .video
        default: return nil
        }
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
