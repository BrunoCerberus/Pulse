import Foundation

/// View events for the Story Threads feature.
enum StoryThreadViewEvent: Equatable {
    case onAppear
    case didTapThread(id: UUID)
    case didToggleFollow(id: UUID)
    case didRequestSummary(id: UUID)
    case didPullToRefresh
}
