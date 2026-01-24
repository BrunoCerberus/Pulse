import Foundation

/// Parses deeplinks from push notification payloads.
///
/// Supports three payload formats:
/// 1. Full URL: `{ "deeplink": "pulse://home" }`
/// 2. Legacy article: `{ "articleID": "world/2024/..." }`
/// 3. Type-based: `{ "deeplinkType": "search", "deeplinkQuery": "swift" }`
enum NotificationDeeplinkParser {
    /// Parses a deeplink from push notification userInfo payload.
    ///
    /// - Parameter userInfo: The notification's userInfo dictionary
    /// - Returns: A parsed `Deeplink` if the payload contains valid deeplink data, nil otherwise
    static func parse(from userInfo: [AnyHashable: Any]) -> Deeplink? {
        // Format 1: Full deeplink URL (preferred)
        if let deeplinkURLString = userInfo["deeplink"] as? String,
           let url = URL(string: deeplinkURLString)
        {
            return parseURL(url)
        }

        // Format 2: Legacy articleID support
        if let articleID = userInfo["articleID"] as? String {
            return .article(id: articleID)
        }

        // Format 3: Type-based format
        if let deeplinkType = userInfo["deeplinkType"] as? String {
            return parseTyped(type: deeplinkType, userInfo: userInfo)
        }

        return nil
    }

    /// Parses a deeplink from a URL.
    ///
    /// - Parameter url: The deeplink URL to parse
    /// - Returns: A parsed `Deeplink` if the URL is valid, nil otherwise
    static func parseURL(_ url: URL) -> Deeplink? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              components.scheme == "pulse"
        else {
            return nil
        }

        switch components.host {
        case "home": return .home
        case "feed": return .feed
        case "bookmarks": return .bookmarks
        case "settings": return .settings
        case "search":
            let query = components.queryItems?.first { $0.name == "q" }?.value
            return .search(query: query)
        case "article":
            guard let id = components.queryItems?.first(where: { $0.name == "id" })?.value else {
                return nil
            }
            return .article(id: id)
        default:
            return nil
        }
    }

    /// Parses a typed deeplink from userInfo dictionary.
    ///
    /// - Parameters:
    ///   - type: The deeplink type string
    ///   - userInfo: The notification's userInfo dictionary containing additional parameters
    /// - Returns: A parsed `Deeplink` if the type is valid, nil otherwise
    static func parseTyped(type: String, userInfo: [AnyHashable: Any]) -> Deeplink? {
        switch type {
        case "home": return .home
        case "feed": return .feed
        case "bookmarks": return .bookmarks
        case "settings": return .settings
        case "search":
            let query = userInfo["deeplinkQuery"] as? String
            return .search(query: query)
        case "article":
            guard let id = userInfo["deeplinkId"] as? String else { return nil }
            return .article(id: id)
        default:
            return nil
        }
    }
}
