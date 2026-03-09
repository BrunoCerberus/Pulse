import Foundation

/// Domain actions for the Story Threads feature.
enum StoryThreadDomainAction: Equatable {
    case loadFollowedThreads
    case loadThreadsForArticle(articleID: String)
    case followThread(id: UUID)
    case unfollowThread(id: UUID)
    case generateSummary(threadID: UUID)
    case markThreadAsRead(id: UUID)
    case refresh
}
