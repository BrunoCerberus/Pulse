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
        notificationCenter: NotificationCenter = .default
    ) {
        do {
            cloudSyncService = try serviceLocator.retrieve(CloudSyncService.self)
        } catch {
            Logger.shared.service("Failed to retrieve CloudSyncService: \(error)", level: .warning)
            cloudSyncService = LiveCloudSyncService()
        }

        analyticsService = try? serviceLocator.retrieve(AnalyticsService.self)
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
        case let .failed(message):
            analyticsService?.logEvent(.cloudSyncFailed(error: message))
            analyticsService?.recordError(
                NSError(
                    domain: "CloudSync",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: message]
                )
            )
        case .idle:
            break
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
        case .available: return "available"
        case .noAccount: return "no_account"
        case .restricted: return "restricted"
        case .temporarilyUnavailable: return "temporarily_unavailable"
        case .couldNotDetermine: return "could_not_determine"
        }
    }
}
