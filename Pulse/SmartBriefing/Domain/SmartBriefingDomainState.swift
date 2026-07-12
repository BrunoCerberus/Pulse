import Foundation

/// Lifecycle of the current/most-recent Smart Briefing build.
enum SmartBriefingBuildState: Equatable {
    case idle
    case building
    /// A queue was handed off to playback; `count` is its item count.
    case ready(count: Int)
    /// Ran, but nothing was left to play (all candidates already served/read).
    case empty
    case error(String)
}

/// Domain state for the Smart Briefing feature.
struct SmartBriefingDomainState: Equatable {
    var buildState: SmartBriefingBuildState = .idle
    /// Mirrors `SmartBriefingCacheService.fetchLastServed()`, so the UI can
    /// show a "last briefed 3h ago" label without querying the service itself.
    var lastServedAt: Date?
    /// Mirrors `StoreKitService.isPremium` — the card is hidden entirely for
    /// non-premium users (Home shouldn't duplicate the Feed tab's upsell).
    var isPremium: Bool = false

    static let initial = SmartBriefingDomainState()
}
