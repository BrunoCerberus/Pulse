import Foundation

/// Domain state for the For You settings screen.
///
/// Mirrors the shape of `BookmarksDomainState` — feature is small and
/// purely a CRUD over the interest profile, no async-heavy flows.
struct ForYouSettingsDomainState: Equatable {
    /// User's interest topics, sorted by weight descending. Empty means
    /// the profile has been reset or onboarding hasn't seeded yet.
    var topics: [InterestTopic]

    /// Indicates the initial fetch is in progress.
    var isLoading: Bool

    /// Last error message, if any (fetch / remove / reset failures).
    var error: String?

    /// Whether the destructive "reset profile" alert is presented.
    var showResetConfirmation: Bool

    static var initial: ForYouSettingsDomainState {
        ForYouSettingsDomainState(
            topics: [],
            isLoading: false,
            error: nil,
            showResetConfirmation: false
        )
    }
}
