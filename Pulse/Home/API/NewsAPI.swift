import EntropyCore
import Foundation

/// HTTP-header carrier for the NewsAPI.org API key. Sending the key in
/// `X-Api-Key` keeps it out of the URL query string — query strings are
/// logged by HTTP intermediaries (CDNs, proxies, browser history when a
/// link is shared, server access logs), so headers are the safer channel.
private struct NewsAPIAuthHeader: Codable {
    let xApiKey: String

    enum CodingKeys: String, CodingKey {
        case xApiKey = "X-Api-Key"
    }
}

enum NewsAPI: APIFetcher {
    case topHeadlines(country: String, page: Int)
    case topHeadlinesByCategory(category: NewsCategory, country: String, page: Int)
    case everything(query: String, page: Int, sortBy: String)
    case sources(category: String?, country: String?)

    private var baseURL: String {
        BaseURLs.newsAPI
    }

    private var apiKey: String {
        APIKeysProvider.newsAPIKey
    }

    var path: String {
        guard var components = URLComponents(string: baseURL) else {
            preconditionFailure("Invalid base URL: \(baseURL)")
        }

        var queryItems: [URLQueryItem] = []

        switch self {
        case let .topHeadlines(country, page):
            components.path += "/top-headlines"
            queryItems.append(URLQueryItem(name: "country", value: country))
            queryItems.append(URLQueryItem(name: "page", value: String(page)))
            queryItems.append(URLQueryItem(name: "pageSize", value: "20"))

        case let .topHeadlinesByCategory(category, country, page):
            components.path += "/top-headlines"
            queryItems.append(URLQueryItem(name: "country", value: country))
            queryItems.append(URLQueryItem(name: "category", value: category.apiParameter))
            queryItems.append(URLQueryItem(name: "page", value: String(page)))
            queryItems.append(URLQueryItem(name: "pageSize", value: "20"))

        case let .everything(query, page, sortBy):
            components.path += "/everything"
            queryItems.append(URLQueryItem(name: "q", value: query))
            queryItems.append(URLQueryItem(name: "page", value: String(page)))
            queryItems.append(URLQueryItem(name: "pageSize", value: "20"))
            queryItems.append(URLQueryItem(name: "sortBy", value: sortBy))

        case let .sources(category, country):
            components.path += "/top-headlines/sources"
            if let category {
                queryItems.append(URLQueryItem(name: "category", value: category))
            }
            if let country {
                queryItems.append(URLQueryItem(name: "country", value: country))
            }
        }

        components.queryItems = queryItems

        guard let urlString = components.string else {
            preconditionFailure("Failed to construct URL from components")
        }

        return urlString
    }

    var method: HTTPMethod {
        .GET
    }

    var task: (any Codable)? {
        nil
    }

    /// API key travels in `X-Api-Key` header — see `NewsAPIAuthHeader`.
    var header: (any Codable)? {
        NewsAPIAuthHeader(xApiKey: apiKey)
    }

    var debug: Bool {
        #if DEBUG
            return true
        #else
            return false
        #endif
    }
}
