import Foundation

/// Actions for the Smart Briefing feature.
enum SmartBriefingDomainAction: Equatable {
    /// Populates `lastServedAt` from the cache on appear.
    case loadLastServedMetadata
    case startBriefing(scope: SmartBriefingScope)
    /// `servedAt` is the cache's current last-served timestamp — `nil` if
    /// nothing has ever been served, unchanged from the prior run if this
    /// build produced zero items (nothing was actually persisted), or fresh
    /// if this run served new articles.
    case buildSucceeded(itemCount: Int, servedAt: Date?)
    case buildFailed(String)
    /// Resets `buildState` to `.idle` after the transient ready/empty/error
    /// status has been shown for a few seconds, so it doesn't linger
    /// indefinitely across `HomeView` appearances.
    case dismissStatus
}

/// How far back a Smart Briefing run should look for candidate articles.
enum SmartBriefingScope: Equatable {
    /// Default: articles published since the last Smart Briefing was served,
    /// falling back to "all unread" if there's no prior briefing.
    case unreadSinceLastBriefing
    /// Explicit "give me everything unread" — ignores the last-served cutoff.
    case allUnread
}
