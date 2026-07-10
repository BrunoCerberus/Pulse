import Foundation

/// Actions for the Smart Briefing feature.
enum SmartBriefingDomainAction: Equatable {
    /// Populates `lastServedAt` from the cache on appear.
    case loadLastServedMetadata
    case startBriefing(scope: SmartBriefingScope)
    case buildSucceeded(itemCount: Int, servedAt: Date)
    case buildFailed(String)
}

/// How far back a Smart Briefing run should look for candidate articles.
enum SmartBriefingScope: Equatable {
    /// Default: articles published since the last Smart Briefing was served,
    /// falling back to "all unread" if there's no prior briefing.
    case unreadSinceLastBriefing
    /// Explicit "give me everything unread" — ignores the last-served cutoff.
    case allUnread
}
