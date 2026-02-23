import EntropyCore
import Foundation
import UIKit

/// Navigation events that can be triggered from the Reading History screen.
enum ReadingHistoryNavigationEvent {
    /// Navigate to article detail
    case articleDetail(Article)
}

/// Router for Reading History module navigation.
@MainActor
final class ReadingHistoryNavigationRouter: NavigationRouter, Equatable {
    nonisolated(unsafe) var navigation: UINavigationController?
    private nonisolated(unsafe) weak var coordinator: Coordinator?

    init(coordinator: Coordinator? = nil) {
        self.coordinator = coordinator
    }

    func route(navigationEvent: ReadingHistoryNavigationEvent) {
        guard let coordinator else { return }

        switch navigationEvent {
        case let .articleDetail(article):
            coordinator.push(page: .articleDetail(article))
        }
    }
}

extension ReadingHistoryNavigationRouter {
    nonisolated static func == (lhs: ReadingHistoryNavigationRouter, rhs: ReadingHistoryNavigationRouter) -> Bool {
        lhs.coordinator === rhs.coordinator
    }
}
