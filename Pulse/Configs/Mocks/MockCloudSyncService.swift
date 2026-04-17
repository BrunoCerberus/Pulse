import Combine
import Foundation

/// In-memory `CloudSyncService` used by unit tests and SwiftUI previews.
///
/// Both state subjects are exposed through helper mutators (`emit(...)`) so
/// tests can drive transitions deterministically. `startObserving()` /
/// `stopObserving()` just flip `isObserving` and record call counts — no real
/// notification center subscriptions are set up.
final class MockCloudSyncService: CloudSyncService {
    private let accountStatusSubject: CurrentValueSubject<CloudSyncAccountStatus, Never>
    private let syncStateSubject: CurrentValueSubject<CloudSyncState, Never>

    private(set) var startObservingCallCount = 0
    private(set) var stopObservingCallCount = 0
    private(set) var refreshAccountStatusCallCount = 0
    private(set) var isObserving = false

    var accountStatusPublisher: AnyPublisher<CloudSyncAccountStatus, Never> {
        accountStatusSubject
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var syncStatePublisher: AnyPublisher<CloudSyncState, Never> {
        syncStateSubject
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var isAvailable: Bool {
        accountStatusSubject.value == .available
    }

    init(
        accountStatus: CloudSyncAccountStatus = .available,
        syncState: CloudSyncState = .idle
    ) {
        accountStatusSubject = CurrentValueSubject(accountStatus)
        syncStateSubject = CurrentValueSubject(syncState)
    }

    func startObserving() {
        startObservingCallCount += 1
        isObserving = true
    }

    func stopObserving() {
        stopObservingCallCount += 1
        isObserving = false
    }

    func refreshAccountStatus() {
        refreshAccountStatusCallCount += 1
    }

    // MARK: - Test helpers

    func emit(accountStatus: CloudSyncAccountStatus) {
        accountStatusSubject.send(accountStatus)
    }

    func emit(syncState: CloudSyncState) {
        syncStateSubject.send(syncState)
    }
}
