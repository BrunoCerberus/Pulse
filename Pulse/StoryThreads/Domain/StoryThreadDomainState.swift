import Foundation

/// Domain state for the Story Threads feature.
struct StoryThreadDomainState: Equatable {
    var threads: [StoryThread]
    var isLoading: Bool
    var isRefreshing: Bool
    var error: String?
    var selectedThreadID: UUID?
    var generatingSummaryForID: UUID?

    static var initial: StoryThreadDomainState {
        StoryThreadDomainState(
            threads: [],
            isLoading: false,
            isRefreshing: false,
            error: nil,
            selectedThreadID: nil,
            generatingSummaryForID: nil
        )
    }

    static func == (lhs: StoryThreadDomainState, rhs: StoryThreadDomainState) -> Bool {
        lhs.threads.map(\.id) == rhs.threads.map(\.id)
            && lhs.threads.map(\.isFollowing) == rhs.threads.map(\.isFollowing)
            && lhs.threads.map(\.updatedAt) == rhs.threads.map(\.updatedAt)
            && lhs.threads.map(\.lastReadAt) == rhs.threads.map(\.lastReadAt)
            && lhs.threads.map(\.summary) == rhs.threads.map(\.summary)
            && lhs.isLoading == rhs.isLoading
            && lhs.isRefreshing == rhs.isRefreshing
            && lhs.error == rhs.error
            && lhs.selectedThreadID == rhs.selectedThreadID
            && lhs.generatingSummaryForID == rhs.generatingSummaryForID
    }
}
