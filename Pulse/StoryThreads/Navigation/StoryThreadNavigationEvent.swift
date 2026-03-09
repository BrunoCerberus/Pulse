import Foundation

/// Navigation events for the Story Threads feature.
enum StoryThreadNavigationEvent {
    /// Navigate to a thread's detail view.
    case threadDetail(StoryThreadItem)

    /// Navigate to an article detail from a thread.
    case articleDetail(Article)
}
