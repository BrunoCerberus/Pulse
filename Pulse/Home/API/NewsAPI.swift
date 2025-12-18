import Foundation
import EntropyCore

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
            fatalError("Invalid base URL: \(baseURL)")
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
            if let category = category {
                queryItems.append(URLQueryItem(name: "category", value: category))
            }
            if let country = country {
                queryItems.append(URLQueryItem(name: "country", value: country))
            }
        }

        queryItems.append(URLQueryItem(name: "apiKey", value: apiKey))
        components.queryItems = queryItems

        guard let urlString = components.string else {
            fatalError("Failed to construct URL from components")
        }

        return urlString
    }

    var method: HTTPMethod {
        .GET
    }

    var task: (any Codable)? { nil }

    var header: (any Codable)? { nil }

    var debug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
}
