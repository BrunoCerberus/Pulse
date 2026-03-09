import Foundation
import SwiftData

/// A story thread groups related news articles into an evolving story arc.
///
/// Users can follow developing stories over time and track new articles
/// added to threads they're interested in.
@Model
final class StoryThread {
    @Attribute(.unique) var id: UUID
    var title: String
    var summary: String
    var articleIDs: [String]
    var category: String
    var isFollowing: Bool
    var createdAt: Date
    var updatedAt: Date
    var lastReadAt: Date?

    init(
        id: UUID = UUID(),
        title: String,
        summary: String,
        articleIDs: [String] = [],
        category: String,
        isFollowing: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        lastReadAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.articleIDs = articleIDs
        self.category = category
        self.isFollowing = isFollowing
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastReadAt = lastReadAt
    }

    /// Number of unread articles since the user last viewed this thread.
    var unreadCount: Int {
        guard let lastReadAt else { return articleIDs.count }
        // Without article dates, we approximate: if updatedAt > lastReadAt, there are unread articles
        return updatedAt > lastReadAt ? 1 : 0
    }
}
