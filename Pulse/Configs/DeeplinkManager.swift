import Combine
import Foundation

enum Deeplink: Equatable {
    case home
    case media(type: MediaType? = nil)
    case search(query: String? = nil)
    case bookmarks
    case feed
    case settings
    case article(id: String)
    case category(name: String)
}

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
