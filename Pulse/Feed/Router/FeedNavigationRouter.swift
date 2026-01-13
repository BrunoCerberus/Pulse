import EntropyCore
import Foundation
import UIKit

/// Navigation events that can be triggered from the Feed screen.
enum FeedNavigationEvent {
    /// Navigate to article detail
    case articleDetail(Article)

    /// Navigate to settings
    case settings
}

/// Router for Feed module navigation.
///
/// Supports SwiftUI navigation via Coordinator.
///
/// @MainActor ensures all navigation operations happen on the main thread.
@MainActor
final class FeedNavigationRouter: NavigationRouter, Equatable {
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
    func route(navigationEvent: FeedNavigationEvent) {
        guard let coordinator else { return }

        switch navigationEvent {
        case let .articleDetail(article):
            coordinator.push(page: .articleDetail(article))
        case .settings:
            coordinator.push(page: .settings)
        }
    }
}

extension FeedNavigationRouter {
    /// Compare routers by their underlying coordinator reference
    nonisolated static func == (lhs: FeedNavigationRouter, rhs: FeedNavigationRouter) -> Bool {
        lhs.coordinator === rhs.coordinator
    }
}
