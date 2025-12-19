import Foundation

/// Navigation events that can be triggered from the Search screen.
enum SearchNavigationEvent {
    /// Navigate to article detail
    case articleDetail(Article)
}

/// Routes Search navigation events to the Coordinator.
@MainActor
final class SearchNavigationRouter {
    private weak var coordinator: Coordinator?

    /// Creates a router with a coordinator reference.
    /// - Parameter coordinator: The coordinator to route events through
    init(coordinator: Coordinator?) {
        self.coordinator = coordinator
    }

    /// Routes a navigation event to the appropriate destination.
    /// - Parameter event: The navigation event to handle
    func route(event: SearchNavigationEvent) {
        guard let coordinator else { return }

        switch event {
        case let .articleDetail(article):
            coordinator.push(page: .articleDetail(article))
        }
    }
}
