import Foundation

/// Navigation events that can be triggered from the Home screen.
enum HomeNavigationEvent {
    /// Navigate to article detail
    case articleDetail(Article)

    /// Navigate to settings
    case settings
}

/// Routes Home navigation events to the Coordinator.
///
/// This router decouples navigation logic from the HomeView, allowing the view
/// to trigger navigation events without knowing about the navigation implementation.
@MainActor
final class HomeNavigationRouter {
    private weak var coordinator: Coordinator?

    /// Creates a router with a coordinator reference.
    /// - Parameter coordinator: The coordinator to route events through
    init(coordinator: Coordinator?) {
        self.coordinator = coordinator
    }

    /// Routes a navigation event to the appropriate destination.
    /// - Parameter event: The navigation event to handle
    func route(event: HomeNavigationEvent) {
        guard let coordinator else { return }

        switch event {
        case let .articleDetail(article):
            coordinator.push(page: .articleDetail(article))
        case .settings:
            coordinator.push(page: .settings)
        }
    }
}
