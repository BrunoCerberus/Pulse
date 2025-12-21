import EntropyCore
import Foundation

enum GuardianAPI: APIFetcher {
    case search(query: String?, section: String?, page: Int, pageSize: Int, orderBy: String)
    case sections

    private var baseURL: String {
        BaseURLs.guardianAPI
    }

    private var apiKey: String {
        APIKeysProvider.guardianAPIKey
    }

    var path: String {
        guard var components = URLComponents(string: baseURL) else {
            fatalError("Invalid base URL: \(baseURL)")
        }

        var queryItems: [URLQueryItem] = []

        switch self {
        case let .search(query, section, page, pageSize, orderBy):
            components.path += "/search"

            if let query = query, !query.isEmpty {
                queryItems.append(URLQueryItem(name: "q", value: query))
            }
            if let section = section {
                queryItems.append(URLQueryItem(name: "section", value: section))
            }
            queryItems.append(URLQueryItem(name: "page", value: String(page)))
            queryItems.append(URLQueryItem(name: "page-size", value: String(pageSize)))
            queryItems.append(URLQueryItem(name: "order-by", value: orderBy))
            queryItems.append(URLQueryItem(name: "show-fields", value: "thumbnail,trailText,body,byline"))

        case .sections:
            components.path += "/sections"
        }

        queryItems.append(URLQueryItem(name: "api-key", value: apiKey))
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
