import EntropyCore
import Foundation
import UIKit

/// Navigation events that can be triggered from the Search screen.
enum SearchNavigationEvent {
    /// Navigate to article detail
    case articleDetail(Article)
}

/// Router for Search module navigation.
///
/// @MainActor ensures all navigation operations happen on the main thread.
@MainActor
final class SearchNavigationRouter: NavigationRouter, Equatable {
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
    func route(navigationEvent: SearchNavigationEvent) {
        guard let coordinator else { return }

        switch navigationEvent {
        case let .articleDetail(article):
            coordinator.push(page: .articleDetail(article))
        }
    }
}

extension SearchNavigationRouter {
    /// Compare routers by their underlying coordinator reference
    nonisolated static func == (lhs: SearchNavigationRouter, rhs: SearchNavigationRouter) -> Bool {
        lhs.coordinator === rhs.coordinator
    }
}
