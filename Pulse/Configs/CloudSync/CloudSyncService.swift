import Combine
import Foundation

// MARK: - Account Status

/// Availability of the user's iCloud account from the app's perspective.
///
/// Mirrors `CKAccountStatus` but adds `.temporarilyUnavailable` as a separate
/// case so the domain layer can react to transient failures distinctly from
/// "the user isn't signed in at all".
enum CloudSyncAccountStatus: Equatable {
    case available
    case noAccount
    case restricted
    case temporarilyUnavailable
    case couldNotDetermine
}

// MARK: - Sync State

/// Last known state of the CloudKit sync engine underlying SwiftData.
enum CloudSyncState: Equatable {
    case idle
    case syncing
    case succeeded(Date)
    case failed(String)
}

// MARK: - Protocol

/// Surfaces the lifecycle of SwiftData's CloudKit-backed private sync.
///
/// The underlying sync is handled by `NSPersistentCloudKitContainer`; this
/// service exposes two `Combine` publishers so the domain layer can reason
/// about iCloud availability + per-event success/failure without touching
/// CloudKit APIs directly.
protocol CloudSyncService: AnyObject {
    /// Current iCloud account availability. Deduplicated.
    var accountStatusPublisher: AnyPublisher<CloudSyncAccountStatus, Never> { get }

    /// Most recent sync state from `NSPersistentCloudKitContainer` events.
    var syncStatePublisher: AnyPublisher<CloudSyncState, Never> { get }

    /// Synchronous convenience — returns `true` only when the account is `.available`.
    var isAvailable: Bool { get }

    /// Starts observing CloudKit + account notifications and seeds the
    /// account status. Idempotent.
    func startObserving()

    /// Stops observing and clears subscriptions.
    func stopObserving()

    /// Re-queries `CKContainer.accountStatus` and pushes the latest value.
    func refreshAccountStatus()
}
