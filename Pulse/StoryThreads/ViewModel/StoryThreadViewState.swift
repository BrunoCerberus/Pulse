import Foundation

/// View state for the Story Threads list.
struct StoryThreadViewState: Equatable {
    var threads: [StoryThreadItem]
    var isLoading: Bool
    var isRefreshing: Bool
    var showEmptyState: Bool
    var errorMessage: String?
    var generatingSummaryForID: UUID?

    static var initial: StoryThreadViewState {
        StoryThreadViewState(
            threads: [],
            isLoading: false,
            isRefreshing: false,
            showEmptyState: false,
            errorMessage: nil,
            generatingSummaryForID: nil
        )
    }
}

/// View model item representing a single story thread in the list.
struct StoryThreadItem: Identifiable, Equatable {
    let id: UUID
    let title: String
    let articleCount: Int
    let unreadCount: Int
    let lastUpdated: String
    let summary: String
    let category: String
    let isFollowing: Bool

    init(from thread: StoryThread) {
        id = thread.id
        title = thread.title
        articleCount = thread.articleIDs.count
        unreadCount = thread.unreadCount
        lastUpdated = Self.relativeDate(from: thread.updatedAt)
        summary = thread.summary
        category = thread.category
        isFollowing = thread.isFollowing
    }

    private static let formatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    private static func relativeDate(from date: Date) -> String {
        formatter.localizedString(for: date, relativeTo: .now)
    }
}
