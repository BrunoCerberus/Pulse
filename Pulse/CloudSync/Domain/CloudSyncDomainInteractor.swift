import Combine
import EntropyCore
import Foundation

/// Domain interactor exposing CloudKit sync lifecycle to the app.
///
/// Subscribes to `CloudSyncService` publishers and:
/// - Publishes a `CloudSyncDomainState` for any future UI consumer.
/// - Logs analytics events on each sync-state transition.
/// - Posts `NotificationCenter.default` `.cloudSyncDidComplete` when a sync
///   finishes successfully so feature interactors can reload from storage.
///
/// Always-on: instantiated by `PulseSceneDelegate` at scene-connect time and
/// retained for the scene's lifetime. No UI entry point.
@MainActor
final class CloudSyncDomainInteractor: CombineInteractor {
    typealias DomainState = CloudSyncDomainState
    typealias DomainAction = CloudSyncDomainAction

    private let cloudSyncService: CloudSyncService
    private let analyticsService: AnalyticsService?
    private let notificationCenter: NotificationCenter
    /// Optional because some test locators don't register them; when present,
    /// a completed sync triggers a CloudKit-merge dedupe pass (H8).
    private let storageService: StorageService?
    private let interestProfileService: InterestProfileService?
    private let stateSubject = CurrentValueSubject<DomainState, Never>(.initial)
    private var cancellables = Set<AnyCancellable>()
    private var previousAccountStatus: CloudSyncAccountStatus = .couldNotDetermine

    var statePublisher: AnyPublisher<DomainState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var currentState: DomainState {
        stateSubject.value
    }

    init(
        serviceLocator: ServiceLocator,
        notificationCenter: NotificationCenter = .default,
    ) {
        do {
            cloudSyncService = try serviceLocator.retrieve(CloudSyncService.self)
        } catch {
            Logger.shared.service("Failed to retrieve CloudSyncService: \(error)", level: .warning)
            cloudSyncService = LiveCloudSyncService()
        }

        analyticsService = try? serviceLocator.retrieve(AnalyticsService.self)
        storageService = try? serviceLocator.retrieve(StorageService.self)
        interestProfileService = try? serviceLocator.retrieve(InterestProfileService.self)
        self.notificationCenter = notificationCenter

        observeServicePublishers()
    }

    func dispatch(action: DomainAction) {
        switch action {
        case .startObserving:
            cloudSyncService.startObserving()
        case .stopObserving:
            cloudSyncService.stopObserving()
        case .refreshAccountStatus:
            cloudSyncService.refreshAccountStatus()
        }
    }

    // MARK: - Observation

    private func observeServicePublishers() {
        cloudSyncService.accountStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.handleAccountStatus(status)
            }
            .store(in: &cancellables)

        cloudSyncService.syncStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] syncState in
                self?.handleSyncState(syncState)
            }
            .store(in: &cancellables)
    }

    private func handleAccountStatus(_ status: CloudSyncAccountStatus) {
        let wasAvailable = previousAccountStatus == .available
        let isAvailableNow = status == .available

        updateState { state in
            state.accountStatus = status
        }

        let wasIndeterminate = previousAccountStatus == .couldNotDetermine
        let isNewTransition = status != previousAccountStatus
        let wasKnownStateBefore = wasAvailable || wasIndeterminate
        if isNewTransition, !isAvailableNow, wasKnownStateBefore {
            analyticsService?.logEvent(.cloudSyncAccountUnavailable(status: status.analyticsValue))
        }

        previousAccountStatus = status
    }

    private func handleSyncState(_ syncState: CloudSyncState) {
        updateState { state in
            state.syncState = syncState
        }

        switch syncState {
        case .syncing:
            analyticsService?.logEvent(.cloudSyncStarted)
        case let .succeeded(date):
            updateState { state in
                state.lastSyncedAt = date
            }
            analyticsService?.logEvent(.cloudSyncSucceeded)
            notificationCenter.post(name: .cloudSyncDidComplete, object: nil)
            deduplicateAfterSync()
        case let .failed(message):
            analyticsService?.logEvent(.cloudSyncFailed(error: message))
            analyticsService?.recordError(
                NSError(
                    domain: "CloudSync",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: message],
                ),
            )
        case .idle:
            break
        }
    }

    /// Collapses duplicate rows a cross-device CloudKit merge can leave (H8),
    /// then re-posts `.cloudSyncDidComplete` so feature interactors reload the
    /// cleaned data — but only when dedupe actually removed rows, so the common
    /// no-duplicates sync stays a single reload. Runs in a detached `Task` so
    /// the sync-state handler isn't blocked on the (rare) dedupe work. The
    /// services aren't `Sendable`, so they're boxed per the project convention
    /// (see `TopicExtractionDrainer`).
    private func deduplicateAfterSync() {
        guard storageService != nil || interestProfileService != nil else { return }
        let storageBox = storageService.map { UncheckedSendableBox(value: $0) }
        let profileBox = interestProfileService.map { UncheckedSendableBox(value: $0) }
        Task { @MainActor [weak self] in
            var changed = false
            if let storageBox, let didChange = try? await storageBox.value.deduplicate() {
                changed = changed || didChange
            }
            if let profileBox, let didChange = try? await profileBox.value.deduplicate() {
                changed = changed || didChange
            }
            if changed {
                self?.notificationCenter.post(name: .cloudSyncDidComplete, object: nil)
            }
        }
    }

    private func updateState(_ transform: (inout DomainState) -> Void) {
        var state = stateSubject.value
        transform(&state)
        stateSubject.send(state)
    }
}

private extension CloudSyncAccountStatus {
    var analyticsValue: String {
        switch self {
        case .available: "available"
        case .noAccount: "no_account"
        case .restricted: "restricted"
        case .temporarilyUnavailable: "temporarily_unavailable"
        case .couldNotDetermine: "could_not_determine"
        }
    }
}
