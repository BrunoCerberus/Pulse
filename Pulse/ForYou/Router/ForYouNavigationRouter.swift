import Foundation

/// Navigation events that can be triggered from the For You screen.
enum ForYouNavigationEvent {
    /// Navigate to article detail
    case articleDetail(Article)

    /// Navigate to settings
    case settings
}

/// Routes For You navigation events to the Coordinator.
@MainActor
final class ForYouNavigationRouter {
    private weak var coordinator: Coordinator?

    /// Creates a router with a coordinator reference.
    /// - Parameter coordinator: The coordinator to route events through
    init(coordinator: Coordinator?) {
        self.coordinator = coordinator
    }

    /// Routes a navigation event to the appropriate destination.
    /// - Parameter event: The navigation event to handle
    func route(event: ForYouNavigationEvent) {
        guard let coordinator else { return }

        switch event {
        case let .articleDetail(article):
            coordinator.push(page: .articleDetail(article))
        case .settings:
            coordinator.push(page: .settings)
        }
    }
}
