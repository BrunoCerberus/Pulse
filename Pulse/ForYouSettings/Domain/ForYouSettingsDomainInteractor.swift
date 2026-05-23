import Combine
import EntropyCore
import Foundation

/// Domain interactor for the For You settings screen.
///
/// CRUDs against `InterestProfileService`; reloads automatically when
/// `.interestProfileDidChange` fires (e.g. after another part of the app
/// reinforces a topic, or after a CloudKit sync merge).
@MainActor
final class ForYouSettingsDomainInteractor: CombineInteractor {
    typealias DomainState = ForYouSettingsDomainState
    typealias DomainAction = ForYouSettingsDomainAction

    private let profileService: InterestProfileService?
    private let analyticsService: AnalyticsService?
    private let stateSubject = CurrentValueSubject<DomainState, Never>(.initial)
    private var cancellables = Set<AnyCancellable>()

    var statePublisher: AnyPublisher<DomainState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var currentState: DomainState {
        stateSubject.value
    }

    init(serviceLocator: ServiceLocator) {
        profileService = try? serviceLocator.retrieve(InterestProfileService.self)
        analyticsService = try? serviceLocator.retrieve(AnalyticsService.self)

        observeProfileChanges()
        observeCloudSync()
    }

    func dispatch(action: DomainAction) {
        switch action {
        case .loadProfile:
            loadProfile()
        case let .removeTopic(topicID):
            removeTopic(topicID: topicID)
        case .requestReset:
            updateState { $0.showResetConfirmation = true }
        case .confirmReset:
            confirmReset()
        case .cancelReset:
            updateState { $0.showResetConfirmation = false }
        }
    }

    // MARK: - Subscriptions

    private func observeProfileChanges() {
        NotificationCenter.default.publisher(for: .interestProfileDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loadProfile()
            }
            .store(in: &cancellables)
    }

    private func observeCloudSync() {
        NotificationCenter.default.publisher(for: .cloudSyncDidComplete)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loadProfile()
            }
            .store(in: &cancellables)
    }

    // MARK: - Profile operations

    private func loadProfile() {
        guard let profileService else { return }
        updateState { state in
            state.isLoading = true
            state.error = nil
        }
        let service = UncheckedSendableBox(value: profileService)
        Task { [weak self] in
            do {
                let topics = try await service.value.fetchProfile()
                await MainActor.run { [weak self] in
                    self?.updateState { state in
                        state.topics = topics
                        state.isLoading = false
                    }
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.updateState { state in
                        state.error = error.localizedDescription
                        state.isLoading = false
                    }
                    self?.analyticsService?.recordError(error)
                }
            }
        }
    }

    private func removeTopic(topicID: String) {
        guard let profileService else { return }
        let service = UncheckedSendableBox(value: profileService)
        Task { [weak self] in
            do {
                try await service.value.remove(topicID: topicID)
                // Live service posts `.interestProfileDidChange`, which
                // triggers `loadProfile()` via our subscription. No need
                // to manually mutate state here.
                _ = self
            } catch {
                await MainActor.run { [weak self] in
                    self?.updateState { state in
                        state.error = error.localizedDescription
                    }
                    self?.analyticsService?.recordError(error)
                }
            }
        }
    }
    
    deinit {
        // Cancel all pending tasks on deallocation
        for task in backgroundTasks {
            task.cancel()
        }
    }

    private func confirmReset() {
        guard let profileService else { return }
        updateState { $0.showResetConfirmation = false }
        let service = UncheckedSendableBox(value: profileService)
        Task { [weak self] in
            do {
                try await service.value.resetProfile()
                _ = self
            } catch {
                await MainActor.run { [weak self] in
                    self?.updateState { state in
                        state.error = error.localizedDescription
                    }
                    self?.analyticsService?.recordError(error)
                }
            }
        }
    }

    private func updateState(_ transform: (inout DomainState) -> Void) {
        var state = stateSubject.value
        transform(&state)
        stateSubject.send(state)
    }
}
