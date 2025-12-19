import Foundation

/// Navigation events that can be triggered from the Categories screen.
enum CategoriesNavigationEvent {
    /// Navigate to article detail
    case articleDetail(Article)
}

/// Routes Categories navigation events to the Coordinator.
@MainActor
final class CategoriesNavigationRouter {
    private weak var coordinator: Coordinator?

    /// Creates a router with a coordinator reference.
    /// - Parameter coordinator: The coordinator to route events through
    init(coordinator: Coordinator?) {
        self.coordinator = coordinator
    }

    /// Routes a navigation event to the appropriate destination.
    /// - Parameter event: The navigation event to handle
    func route(event: CategoriesNavigationEvent) {
        guard let coordinator else { return }

        switch event {
        case let .articleDetail(article):
            coordinator.push(page: .articleDetail(article))
        }
    }
}
