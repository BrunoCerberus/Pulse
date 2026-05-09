import Foundation

/// Actions dispatched to `ForYouSettingsDomainInteractor`.
enum ForYouSettingsDomainAction: Equatable {
    /// Load the interest profile from storage. Dispatched on view appear
    /// and when `.interestProfileDidChange` fires.
    case loadProfile

    /// Remove a single topic. Triggered by swipe-to-delete on a row.
    case removeTopic(topicID: String)

    /// Show the destructive confirmation alert before resetting.
    case requestReset

    /// User confirmed: wipe every topic.
    case confirmReset

    /// User cancelled the reset alert.
    case cancelReset
}
