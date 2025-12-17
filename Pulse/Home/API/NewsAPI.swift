import Foundation
import EntropyCore

enum NewsAPI: APIFetcher {
    case topHeadlines(country: String, page: Int)
    case topHeadlinesByCategory(category: NewsCategory, country: String, page: Int)
    case everything(query: String, page: Int, sortBy: String)
    case sources(category: String?, country: String?)

    var baseURL: String {
        BaseURLs.newsAPI
    }

    var path: String {
        switch self {
        case .topHeadlines:
            return "/top-headlines"
        case .topHeadlinesByCategory:
            return "/top-headlines"
        case .everything:
            return "/everything"
        case .sources:
            return "/top-headlines/sources"
        }
    }

    var method: HTTPMethod {
        .GET
    }

    var queryItems: [URLQueryItem]? {
        var items: [URLQueryItem] = [
            URLQueryItem(name: "apiKey", value: APIKeysProvider.newsAPIKey)
        ]

        switch self {
        case let .topHeadlines(country, page):
            items.append(URLQueryItem(name: "country", value: country))
            items.append(URLQueryItem(name: "page", value: String(page)))
            items.append(URLQueryItem(name: "pageSize", value: "20"))

        case let .topHeadlinesByCategory(category, country, page):
            items.append(URLQueryItem(name: "country", value: country))
            items.append(URLQueryItem(name: "category", value: category.apiParameter))
            items.append(URLQueryItem(name: "page", value: String(page)))
            items.append(URLQueryItem(name: "pageSize", value: "20"))

        case let .everything(query, page, sortBy):
            items.append(URLQueryItem(name: "q", value: query))
            items.append(URLQueryItem(name: "page", value: String(page)))
            items.append(URLQueryItem(name: "pageSize", value: "20"))
            items.append(URLQueryItem(name: "sortBy", value: sortBy))

        case let .sources(category, country):
            if let category = category {
                items.append(URLQueryItem(name: "category", value: category))
            }
            if let country = country {
                items.append(URLQueryItem(name: "country", value: country))
            }
        }

        return items
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
