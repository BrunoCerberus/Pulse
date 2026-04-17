import Foundation

/// Domain state for the CloudKit sync feature.
///
/// Surfaced by `CloudSyncDomainInteractor` to anyone who wants to reason about
/// iCloud availability + most recent sync result. There is no UI consumer
/// today; the state exists so sync behavior is observable via analytics and
/// so future UI (banners, settings, etc.) has a ready-made data source.
struct CloudSyncDomainState: Equatable {
    var accountStatus: CloudSyncAccountStatus
    var syncState: CloudSyncState
    var lastSyncedAt: Date?

    var isAvailable: Bool {
        accountStatus == .available
    }

    static let initial = CloudSyncDomainState(
        accountStatus: .couldNotDetermine,
        syncState: .idle,
        lastSyncedAt: nil
    )
}
