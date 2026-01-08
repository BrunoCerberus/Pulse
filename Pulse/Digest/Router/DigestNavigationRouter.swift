import EntropyCore
import Foundation
import UIKit

/// Navigation events that can be triggered from the Digest screen.
enum DigestNavigationEvent {
    /// Navigate to settings to configure topics
    case settings
    /// Navigate to summary detail view
    case summaryDetail(SummaryItem)
}

/// Router for Digest module navigation.
///
/// @MainActor ensures all navigation operations happen on the main thread.
@MainActor
final class DigestNavigationRouter: NavigationRouter, Equatable {
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
    func route(navigationEvent: DigestNavigationEvent) {
        guard let coordinator else { return }

        switch navigationEvent {
        case .settings:
            coordinator.push(page: .settings)
        case let .summaryDetail(summaryItem):
            coordinator.push(page: .summaryDetail(summaryItem))
        }
    }
}

extension DigestNavigationRouter {
    /// Compare routers by their underlying coordinator reference
    nonisolated static func == (lhs: DigestNavigationRouter, rhs: DigestNavigationRouter) -> Bool {
        lhs.coordinator === rhs.coordinator
    }
}
