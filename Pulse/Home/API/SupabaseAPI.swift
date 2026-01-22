import EntropyCore
import Foundation

/// Supabase REST API endpoints for fetching articles.
///
/// Uses PostgREST query syntax for filtering and pagination.
enum SupabaseAPI: APIFetcher {
    case articles(page: Int, pageSize: Int)
    case articlesByCategory(category: String, page: Int, pageSize: Int)
    case breakingNews(since: String)
    case article(id: String)
    case search(query: String, page: Int, pageSize: Int, orderBy: String)

    private var baseURL: String {
        SupabaseConfig.url + "/rest/v1"
    }

    var path: String {
        guard var components = URLComponents(string: baseURL + "/articles") else {
            Logger.shared.service("SupabaseAPI: Invalid Supabase URL: \(baseURL)", level: .error)
            // Return invalid URL that will fail gracefully at the network layer
            return "https://invalid.supabase.url/articles"
        }

        var queryItems: [URLQueryItem] = []

        // Select only the fields we need (avoids parse errors from search_vector, url_hash, etc.)
        let articleFields = "id,title,summary,content,url,image_url,thumbnail_url,author,published_at"
        let sourceFields = "sources(id,name,slug,logo_url,website_url)"
        let categoryFields = "categories(id,name,slug)"
        let selectValue = "\(articleFields),\(sourceFields),\(categoryFields)"

        queryItems.append(URLQueryItem(name: "select", value: selectValue))

        switch self {
        case let .articles(page, pageSize):
            let offset = (page - 1) * pageSize
            queryItems.append(URLQueryItem(name: "order", value: "published_at.desc"))
            queryItems.append(URLQueryItem(name: "offset", value: String(offset)))
            queryItems.append(URLQueryItem(name: "limit", value: String(pageSize)))

        case let .articlesByCategory(category, page, pageSize):
            let offset = (page - 1) * pageSize
            // Use inner join for category filtering (select specific fields)
            let innerSelectValue = "\(articleFields),\(sourceFields),categories!inner(id,name,slug)"
            queryItems[0] = URLQueryItem(name: "select", value: innerSelectValue)
            queryItems.append(URLQueryItem(name: "categories.slug", value: "eq.\(category)"))
            queryItems.append(URLQueryItem(name: "order", value: "published_at.desc"))
            queryItems.append(URLQueryItem(name: "offset", value: String(offset)))
            queryItems.append(URLQueryItem(name: "limit", value: String(pageSize)))

        case let .breakingNews(since):
            queryItems.append(URLQueryItem(name: "published_at", value: "gte.\(since)"))
            queryItems.append(URLQueryItem(name: "order", value: "published_at.desc"))
            queryItems.append(URLQueryItem(name: "limit", value: "10"))

        case let .article(id):
            queryItems.append(URLQueryItem(name: "id", value: "eq.\(id)"))
            queryItems.append(URLQueryItem(name: "limit", value: "1"))

        case let .search(query, page, pageSize, orderBy):
            let offset = (page - 1) * pageSize
            // Use ilike for case-insensitive search in title and summary
            // PostgREST OR syntax: or=(title.ilike.*query*,summary.ilike.*query*)
            let searchPattern = "*\(query)*"
            queryItems.append(URLQueryItem(name: "or", value: "(title.ilike.\(searchPattern),summary.ilike.\(searchPattern))"))
            // Map order parameter
            let order = orderBy == "relevance" ? "published_at.desc" : "published_at.desc"
            queryItems.append(URLQueryItem(name: "order", value: order))
            queryItems.append(URLQueryItem(name: "offset", value: String(offset)))
            queryItems.append(URLQueryItem(name: "limit", value: String(pageSize)))
        }

        components.queryItems = queryItems

        guard let urlString = components.string else {
            Logger.shared.service("SupabaseAPI: Failed to construct URL from components", level: .error)
            return "https://invalid.supabase.url/articles"
        }

        return urlString
    }

    var method: HTTPMethod {
        .GET
    }

    var task: (any Codable)? { nil }

    var header: (any Codable)? {
        SupabaseHeaders(
            apiKey: SupabaseConfig.anonKey,
            authorization: "Bearer \(SupabaseConfig.anonKey)"
        )
    }

    var debug: Bool {
        #if DEBUG
            return true
        #else
            return false
        #endif
    }
}

// MARK: - Headers

struct SupabaseHeaders: Codable {
    let apiKey: String
    let authorization: String

    enum CodingKeys: String, CodingKey {
        case apiKey = "apikey"
        case authorization = "Authorization"
    }
}
