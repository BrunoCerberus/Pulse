import Combine
import Foundation

/// Represents a navigation destination triggered by a deeplink URL.
///
/// ## Supported URL Formats
/// - `pulse://home` - Navigate to Home tab
/// - `pulse://media?type=video` - Navigate to Media tab with optional type filter
/// - `pulse://search?q=query` - Navigate to Search tab with optional query
/// - `pulse://bookmarks` - Navigate to Bookmarks tab
/// - `pulse://feed` - Navigate to Feed tab (AI Daily Digest)
/// - `pulse://settings` - Navigate to Settings
/// - `pulse://article?id=123` - Open specific article detail
/// - `pulse://category?name=technology` - Filter by category
enum Deeplink: Equatable {
    /// Navigate to the Home tab.
    case home

    /// Navigate to the Media tab with optional type filter.
    case media(type: MediaType? = nil)

    /// Navigate to Search tab with optional pre-filled query.
    case search(query: String? = nil)

    /// Navigate to the Bookmarks tab.
    case bookmarks

    /// Navigate to the Feed tab (AI Daily Digest).
    case feed

    /// Navigate to the Settings screen.
    case settings

    /// Open a specific article by ID.
    case article(id: String)

    /// Filter articles by category name.
    case category(name: String)
}

/// Manages deeplink URL parsing and routing.
///
/// This singleton parses incoming `pulse://` URLs and publishes
/// `Deeplink` events for the `DeeplinkRouter` to handle.
///
/// ## Usage
/// ```swift
/// // In SceneDelegate or App
/// DeeplinkManager.shared.parse(url: url)
///
/// // In Coordinator or Router
/// DeeplinkManager.shared.deeplinkPublisher
///     .sink { deeplink in
///         // Handle navigation
///     }
/// ```
///
/// ## Push Notification Deeplinks
/// For push notification payloads, use `NotificationDeeplinkParser` to
/// convert notification data to a URL, then pass to this manager.
@MainActor
final class DeeplinkManager: ObservableObject {
    static let shared = DeeplinkManager()

    private let deeplinkSubject = PassthroughSubject<Deeplink, Never>()
    var deeplinkPublisher: AnyPublisher<Deeplink, Never> {
        deeplinkSubject.eraseToAnyPublisher()
    }

    @Published private(set) var currentDeeplink: Deeplink?

    private init() {}

    // swiftlint:disable:next cyclomatic_complexity
    func parse(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              components.scheme == "pulse"
        else {
            return
        }

        let deeplink: Deeplink
        switch components.host {
        case "home":
            deeplink = .home
        case "media":
            let typeString = components.queryItems?.first(where: { $0.name == "type" })?.value
            let mediaType = typeString.flatMap { MediaType(rawValue: $0) }
            deeplink = .media(type: mediaType)
        case "search":
            let query = components.queryItems?.first(where: { $0.name == "q" })?.value
            deeplink = .search(query: query)
        case "bookmarks":
            deeplink = .bookmarks
        case "feed":
            deeplink = .feed
        case "settings":
            deeplink = .settings
        case "article":
            guard let articleID = components.queryItems?.first(where: { $0.name == "id" })?.value else {
                return
            }
            deeplink = .article(id: articleID)
        case "category":
            guard let categoryName = components.queryItems?.first(where: { $0.name == "name" })?.value else {
                return
            }
            deeplink = .category(name: categoryName)
        default:
            return
        }

        handle(deeplink: deeplink)
    }

    func handle(deeplink: Deeplink) {
        currentDeeplink = deeplink
        deeplinkSubject.send(deeplink)
    }

    func clearDeeplink() {
        currentDeeplink = nil
    }
}
