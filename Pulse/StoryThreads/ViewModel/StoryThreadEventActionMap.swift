import EntropyCore

/// Maps `StoryThreadViewEvent` to `StoryThreadDomainAction`.
struct StoryThreadEventActionMap: DomainEventActionMap {
    func map(event: StoryThreadViewEvent) -> StoryThreadDomainAction? {
        switch event {
        case .onAppear:
            return .loadFollowedThreads
        case .didTapThread:
            // Navigation handled by router, no domain action needed
            return nil
        case let .didToggleFollow(id):
            // The view will provide context on whether to follow or unfollow
            // For the list view, toggling always unfollows (since list shows followed threads)
            return .unfollowThread(id: id)
        case let .didRequestSummary(id):
            return .generateSummary(threadID: id)
        case .didPullToRefresh:
            return .refresh
        }
    }
}
