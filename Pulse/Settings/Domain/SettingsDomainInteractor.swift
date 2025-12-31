import Combine
import Foundation

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

    init(serviceLocator: ServiceLocator) {
        do {
            settingsService = try serviceLocator.retrieve(SettingsService.self)
        } catch {
            Logger.shared.service("Failed to retrieve SettingsService: \(error)", level: .warning)
            settingsService = LiveSettingsService(storageService: LiveStorageService())
        }
    }

    func dispatch(action: SettingsDomainAction) {
        switch action {
        case .loadPreferences:
            loadPreferences()
        case .clearReadingHistory:
            clearReadingHistory()
        case let .toggleTopic(topic):
            toggleTopic(topic)
        case let .toggleNotifications(enabled):
            toggleNotifications(enabled)
        case let .toggleBreakingNews(enabled):
            toggleBreakingNews(enabled)
        case .addMutedSource, .removeMutedSource, .addMutedKeyword, .removeMutedKeyword:
            handleMutedContentAction(action)
        case .setShowClearHistoryConfirmation, .setShowSignOutConfirmation,
             .setNewMutedSource, .setNewMutedKeyword:
            handleUIStateAction(action)
        }
    }

    private func handleMutedContentAction(_ action: SettingsDomainAction) {
        switch action {
        case let .addMutedSource(source):
            addMutedSource(source)
        case let .removeMutedSource(source):
            removeMutedSource(source)
        case let .addMutedKeyword(keyword):
            addMutedKeyword(keyword)
        case let .removeMutedKeyword(keyword):
            removeMutedKeyword(keyword)
        default:
            break
        }
    }

    private func handleUIStateAction(_ action: SettingsDomainAction) {
        updateState { state in
            switch action {
            case let .setShowClearHistoryConfirmation(show):
                state.showClearHistoryConfirmation = show
            case let .setShowSignOutConfirmation(show):
                state.showSignOutConfirmation = show
            case let .setNewMutedSource(source):
                state.newMutedSource = source
            case let .setNewMutedKeyword(keyword):
                state.newMutedKeyword = keyword
            default:
                break
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
        guard !source.isEmpty else { return }
        var preferences = currentState.preferences
        if !preferences.mutedSources.contains(source) {
            preferences.mutedSources.append(source)
            savePreferences(preferences)
        }
        updateState { state in
            state.newMutedSource = ""
        }
    }

    private func removeMutedSource(_ source: String) {
        var preferences = currentState.preferences
        preferences.mutedSources.removeAll { $0 == source }
        savePreferences(preferences)
    }

    private func addMutedKeyword(_ keyword: String) {
        guard !keyword.isEmpty else { return }
        var preferences = currentState.preferences
        if !preferences.mutedKeywords.contains(keyword) {
            preferences.mutedKeywords.append(keyword)
            savePreferences(preferences)
        }
        updateState { state in
            state.newMutedKeyword = ""
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
    case setShowSignOutConfirmation(Bool)
    case setNewMutedSource(String)
    case setNewMutedKeyword(String)
}
