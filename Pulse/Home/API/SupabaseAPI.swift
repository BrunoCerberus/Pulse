import EntropyCore
import Foundation

/// Supabase Edge Functions API endpoints for fetching articles.
///
/// Uses the cached Edge Functions layer which provides:
/// - Server-side caching with Cache-Control headers
/// - ETag support for conditional requests (304 Not Modified)
/// - No authentication required (public read-only endpoints)
enum SupabaseAPI: APIFetcher {
    case articles(language: String, page: Int, pageSize: Int)
    case articlesByCategory(language: String, category: String, page: Int, pageSize: Int)
    case breakingNews(language: String, limit: Int)
    case article(id: String)
    case search(query: String, page: Int, pageSize: Int)
    case categories
    case sources
    case media(language: String, type: String?, page: Int, pageSize: Int)
    case featuredMedia(language: String, type: String?, limit: Int)

    private var baseURL: String {
        SupabaseConfig.url + "/functions/v1"
    }

    /// Fields to select for article list views (optimized for feed display)
    /// Includes media fields for podcasts/videos support
    private static let listFields = [
        "id", "title", "url", "image_url", "published_at",
        "source_name", "source_slug", "category_name", "category_slug",
        "summary", "content",
        "media_type", "media_url", "media_duration", "media_mime_type",
    ].joined(separator: ",")

    /// Fields to select for article detail views (includes full content)
    private static let detailFields = [
        "id", "title", "url", "image_url", "published_at",
        "source_name", "source_slug", "category_name", "category_slug",
        "summary", "content",
    ].joined(separator: ",")

    var path: String {
        let endpoint: String
        var queryItems: [URLQueryItem] = []

        switch self {
        case let .articles(language, page, pageSize):
            endpoint = "/api-articles"
            let offset = (page - 1) * pageSize
            queryItems.append(URLQueryItem(name: "select", value: Self.listFields))
            queryItems.append(URLQueryItem(name: "language", value: "eq.\(language)"))
            queryItems.append(URLQueryItem(name: "order", value: "published_at.desc"))
            queryItems.append(URLQueryItem(name: "limit", value: String(pageSize)))
            if offset > 0 {
                queryItems.append(URLQueryItem(name: "offset", value: String(offset)))
            }

        case let .articlesByCategory(language, category, page, pageSize):
            endpoint = "/api-articles"
            let offset = (page - 1) * pageSize
            queryItems.append(URLQueryItem(name: "select", value: Self.listFields))
            queryItems.append(URLQueryItem(name: "language", value: "eq.\(language)"))
            queryItems.append(URLQueryItem(name: "category_slug", value: "eq.\(category)"))
            queryItems.append(URLQueryItem(name: "order", value: "published_at.desc"))
            queryItems.append(URLQueryItem(name: "limit", value: String(pageSize)))
            if offset > 0 {
                queryItems.append(URLQueryItem(name: "offset", value: String(offset)))
            }

        case let .breakingNews(language, limit):
            endpoint = "/api-articles"
            queryItems.append(URLQueryItem(name: "select", value: Self.listFields))
            queryItems.append(URLQueryItem(name: "language", value: "eq.\(language)"))
            queryItems.append(URLQueryItem(name: "order", value: "published_at.desc"))
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))

        case let .article(id):
            endpoint = "/api-articles"
            queryItems.append(URLQueryItem(name: "select", value: Self.detailFields))
            queryItems.append(URLQueryItem(name: "id", value: "eq.\(id)"))
            queryItems.append(URLQueryItem(name: "limit", value: "1"))

        case let .search(query, page, pageSize):
            endpoint = "/api-search"
            let offset = (page - 1) * pageSize
            queryItems.append(URLQueryItem(name: "q", value: query))
            queryItems.append(URLQueryItem(name: "limit", value: String(pageSize)))
            if offset > 0 {
                queryItems.append(URLQueryItem(name: "offset", value: String(offset)))
            }

        case .categories:
            endpoint = "/api-categories"

        case .sources:
            endpoint = "/api-sources"

        case let .media(language, type, page, pageSize):
            endpoint = "/api-articles"
            let offset = (page - 1) * pageSize
            queryItems.append(URLQueryItem(name: "select", value: Self.listFields))
            queryItems.append(URLQueryItem(name: "language", value: "eq.\(language)"))

            // Filter by category_slug for media content
            if let type {
                queryItems.append(URLQueryItem(name: "category_slug", value: "eq.\(type)"))
            } else {
                // Both podcasts and videos
                queryItems.append(URLQueryItem(name: "category_slug", value: "in.(podcasts,videos)"))
            }

            queryItems.append(URLQueryItem(name: "order", value: "published_at.desc"))
            queryItems.append(URLQueryItem(name: "limit", value: String(pageSize)))
            if offset > 0 {
                queryItems.append(URLQueryItem(name: "offset", value: String(offset)))
            }

        case let .featuredMedia(language, type, limit):
            endpoint = "/api-articles"
            queryItems.append(URLQueryItem(name: "select", value: Self.listFields))
            queryItems.append(URLQueryItem(name: "language", value: "eq.\(language)"))

            // Filter by category_slug for media content
            if let type {
                queryItems.append(URLQueryItem(name: "category_slug", value: "eq.\(type)"))
            } else {
                // Both podcasts and videos
                queryItems.append(URLQueryItem(name: "category_slug", value: "in.(podcasts,videos)"))
            }

            queryItems.append(URLQueryItem(name: "order", value: "published_at.desc"))
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        }

        guard var components = URLComponents(string: baseURL + endpoint) else {
            Logger.shared.service("SupabaseAPI: Invalid Supabase URL: \(baseURL)", level: .error)
            return "https://invalid.supabase.url/api-articles"
        }

        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let urlString = components.string else {
            Logger.shared.service("SupabaseAPI: Failed to construct URL from components", level: .error)
            return "https://invalid.supabase.url/api-articles"
        }

        return urlString
    }

    var method: HTTPMethod {
        .GET
    }

    var task: (any Codable)? {
        nil
    }

    var header: (any Codable)? {
        // Edge Functions API is public - no authentication required
        // Server-side caching is handled via Cache-Control headers
        // Note: ETag support requires response header access (future enhancement)
        nil
    }

    var debug: Bool {
        #if DEBUG
            return true
        #else
            return false
        #endif
    }
}
