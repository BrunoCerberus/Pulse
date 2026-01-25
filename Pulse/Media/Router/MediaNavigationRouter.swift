import EntropyCore
import Foundation
import UIKit

/// Navigation events that can be triggered from the Media screen.
enum MediaNavigationEvent {
    /// Navigate to media detail (article detail view).
    case mediaDetail(Article)
}

/// Router for Media module navigation.
///
/// Supports SwiftUI navigation via Coordinator.
///
/// @MainActor ensures all navigation operations happen on the main thread.
@MainActor
final class MediaNavigationRouter: NavigationRouter, Equatable {
    /// Optional UIKit navigation controller (required by NavigationRouter protocol).
    nonisolated(unsafe) var navigation: UINavigationController?

    /// SwiftUI coordinator for declarative navigation.
    private nonisolated(unsafe) weak var coordinator: Coordinator?

    /// Creates a router with a coordinator reference.
    /// - Parameter coordinator: The coordinator to route events through.
    init(coordinator: Coordinator? = nil) {
        self.coordinator = coordinator
    }

    /// Routes a navigation event to the appropriate destination.
    /// - Parameter navigationEvent: The navigation event to handle.
    func route(navigationEvent: MediaNavigationEvent) {
        guard let coordinator else { return }

        switch navigationEvent {
        case let .mediaDetail(article):
            coordinator.push(page: .mediaDetail(article))
        }
    }
}

extension MediaNavigationRouter {
    /// Compare routers by their underlying coordinator reference.
    nonisolated static func == (lhs: MediaNavigationRouter, rhs: MediaNavigationRouter) -> Bool {
        lhs.coordinator === rhs.coordinator
    }
}
