import Foundation
import Combine

final class SettingsDomainInteractor: CombineInteractor {
    typealias DomainState = SettingsDomainState
    typealias DomainAction = SettingsDomainAction

    private let settingsService: SettingsService
    private let stateSubject = CurrentValueSubject<SettingsDomainState, Never>(.initial)
    private var cancellables = Set<AnyCancellable>()

    var statePublisher: AnyPublisher<SettingsDomainState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var currentState: SettingsDomainState {
        stateSubject.value
    }

    init(settingsService: SettingsService = ServiceLocator.shared.resolve(SettingsService.self)) {
        self.settingsService = settingsService
    }

    func dispatch(action: SettingsDomainAction) {
        switch action {
        case .loadPreferences:
            loadPreferences()
        case let .toggleTopic(topic):
            toggleTopic(topic)
        case let .toggleNotifications(enabled):
            toggleNotifications(enabled)
        case let .toggleBreakingNews(enabled):
            toggleBreakingNews(enabled)
        case let .addMutedSource(source):
            addMutedSource(source)
        case let .removeMutedSource(source):
            removeMutedSource(source)
        case let .addMutedKeyword(keyword):
            addMutedKeyword(keyword)
        case let .removeMutedKeyword(keyword):
            removeMutedKeyword(keyword)
        case .clearReadingHistory:
            clearReadingHistory()
        case let .setShowClearHistoryConfirmation(show):
            updateState { state in
                state.showClearHistoryConfirmation = show
            }
        }
    }

    private func loadPreferences() {
        updateState { state in
            state.isLoading = true
            state.error = nil
        }

        settingsService.fetchPreferences()
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.updateState { state in
                        state.isLoading = false
                        state.error = error.localizedDescription
                    }
                }
            } receiveValue: { [weak self] preferences in
                self?.updateState { state in
                    state.preferences = preferences
                    state.isLoading = false
                }
            }
            .store(in: &cancellables)
    }

    private func toggleTopic(_ topic: NewsCategory) {
        var preferences = currentState.preferences
        if preferences.followedTopics.contains(topic) {
            preferences.followedTopics.removeAll { $0 == topic }
        } else {
            preferences.followedTopics.append(topic)
        }
        savePreferences(preferences)
    }

    private func toggleNotifications(_ enabled: Bool) {
        var preferences = currentState.preferences
        preferences.notificationsEnabled = enabled
        savePreferences(preferences)
    }

    private func toggleBreakingNews(_ enabled: Bool) {
        var preferences = currentState.preferences
        preferences.breakingNewsNotifications = enabled
        savePreferences(preferences)
    }

    private func addMutedSource(_ source: String) {
        var preferences = currentState.preferences
        if !preferences.mutedSources.contains(source) {
            preferences.mutedSources.append(source)
            savePreferences(preferences)
        }
    }

    private func removeMutedSource(_ source: String) {
        var preferences = currentState.preferences
        preferences.mutedSources.removeAll { $0 == source }
        savePreferences(preferences)
    }

    private func addMutedKeyword(_ keyword: String) {
        var preferences = currentState.preferences
        if !preferences.mutedKeywords.contains(keyword) {
            preferences.mutedKeywords.append(keyword)
            savePreferences(preferences)
        }
    }

    private func removeMutedKeyword(_ keyword: String) {
        var preferences = currentState.preferences
        preferences.mutedKeywords.removeAll { $0 == keyword }
        savePreferences(preferences)
    }

    private func savePreferences(_ preferences: UserPreferences) {
        updateState { state in
            state.isSaving = true
            state.preferences = preferences
        }

        settingsService.savePreferences(preferences)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.updateState { state in
                        state.isSaving = false
                        state.error = error.localizedDescription
                    }
                }
            } receiveValue: { [weak self] in
                self?.updateState { state in
                    state.isSaving = false
                }
            }
            .store(in: &cancellables)
    }

    private func clearReadingHistory() {
        settingsService.clearReadingHistory()
            .sink { _ in } receiveValue: { [weak self] in
                self?.updateState { state in
                    state.showClearHistoryConfirmation = false
                }
            }
            .store(in: &cancellables)
    }

    private func updateState(_ transform: (inout SettingsDomainState) -> Void) {
        var state = stateSubject.value
        transform(&state)
        stateSubject.send(state)
    }
}

enum SettingsDomainAction: Equatable {
    case loadPreferences
    case toggleTopic(NewsCategory)
    case toggleNotifications(Bool)
    case toggleBreakingNews(Bool)
    case addMutedSource(String)
    case removeMutedSource(String)
    case addMutedKeyword(String)
    case removeMutedKeyword(String)
    case clearReadingHistory
    case setShowClearHistoryConfirmation(Bool)
}
