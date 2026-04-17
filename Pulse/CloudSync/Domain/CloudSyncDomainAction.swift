import Foundation

/// Actions dispatched to `CloudSyncDomainInteractor`.
enum CloudSyncDomainAction: Equatable {
    /// Start observing CloudKit + iCloud account notifications.
    case startObserving

    /// Stop observing and drop all subscriptions.
    case stopObserving

    /// Ask the service to re-query the current iCloud account status.
    case refreshAccountStatus
}
