import EntropyCore
import Foundation
import UIKit

/// Navigation events that can be triggered from the Collections screen.
enum CollectionsNavigationEvent {
    /// Navigate to collection detail
    case collectionDetail(Collection)

    /// Navigate to article detail
    case articleDetail(Article)

    /// Navigate to settings
    case settings
}

/// Router for Collections module navigation.
///
/// Supports SwiftUI navigation via Coordinator.
///
/// @MainActor ensures all navigation operations happen on the main thread.
@MainActor
final class CollectionsNavigationRouter: NavigationRouter, Equatable {
    /// Optional UIKit navigation controller (required by NavigationRouter protocol)
    nonisolated(unsafe) var navigation: UINavigationController?

    /// SwiftUI coordinator for declarative navigation
    private nonisolated(unsafe) weak var coordinator: Coordinator?

    /// Creates a router with a coordinator reference.
    /// - Parameter coordinator: The coordinator to route events through
    init(coordinator: Coordinator? = nil) {
        self.coordinator = coordinator
    }

    /// Routes a navigation event to the appropriate destination.
    /// - Parameter navigationEvent: The navigation event to handle
    func route(navigationEvent: CollectionsNavigationEvent) {
        guard let coordinator else { return }

        switch navigationEvent {
        case let .collectionDetail(collection):
            coordinator.push(page: .collectionDetail(collection))
        case let .articleDetail(article):
            coordinator.push(page: .articleDetail(article))
        case .settings:
            coordinator.push(page: .settings)
        }
    }
}

extension CollectionsNavigationRouter {
    /// Compare routers by their underlying coordinator reference
    nonisolated static func == (lhs: CollectionsNavigationRouter, rhs: CollectionsNavigationRouter) -> Bool {
        lhs.coordinator === rhs.coordinator
    }
}
