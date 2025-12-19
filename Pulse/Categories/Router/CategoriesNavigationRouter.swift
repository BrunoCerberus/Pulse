import EntropyCore
import Foundation
import UIKit

/// Navigation events that can be triggered from the Categories screen.
enum CategoriesNavigationEvent {
    /// Navigate to article detail
    case articleDetail(Article)
}

/// Router for Categories module navigation.
///
/// @MainActor ensures all navigation operations happen on the main thread.
@MainActor
final class CategoriesNavigationRouter: NavigationRouter, Equatable {
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
    func route(navigationEvent: CategoriesNavigationEvent) {
        guard let coordinator else { return }

        switch navigationEvent {
        case let .articleDetail(article):
            coordinator.push(page: .articleDetail(article))
        }
    }
}

extension CategoriesNavigationRouter {
    /// Compare routers by their underlying coordinator reference
    nonisolated static func == (lhs: CategoriesNavigationRouter, rhs: CategoriesNavigationRouter) -> Bool {
        lhs.coordinator === rhs.coordinator
    }
}
