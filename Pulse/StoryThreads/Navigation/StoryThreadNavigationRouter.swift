import EntropyCore
import Foundation
import UIKit

/// Router for Story Threads navigation.
@MainActor
final class StoryThreadNavigationRouter: NavigationRouter, Equatable {
    nonisolated(unsafe) var navigation: UINavigationController?
    private nonisolated(unsafe) weak var coordinator: Coordinator?

    init(coordinator: Coordinator? = nil) {
        self.coordinator = coordinator
    }

    func route(navigationEvent: StoryThreadNavigationEvent) {
        guard let coordinator else { return }

        switch navigationEvent {
        case let .threadDetail(item):
            coordinator.push(page: .storyThreadDetail(id: item.id, title: item.title))
        case let .articleDetail(article):
            coordinator.push(page: .articleDetail(article))
        }
    }
}

extension StoryThreadNavigationRouter {
    nonisolated static func == (lhs: StoryThreadNavigationRouter, rhs: StoryThreadNavigationRouter) -> Bool {
        lhs.coordinator === rhs.coordinator
    }
}
