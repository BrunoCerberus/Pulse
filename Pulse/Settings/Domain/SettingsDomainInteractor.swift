import Combine
import EntropyCore
import Foundation

/// Notification posted when user preferences are updated.
/// Used by Home to refresh followed topics when returning from Settings.
extension Notification.Name {
    static let userPreferencesDidChange = Notification.Name("userPreferencesDidChange")
}

/// Domain interactor for the Settings feature.
///
/// Manages business logic and state for user preferences, including:
/// - Loading and saving user preferences
/// - Topic management (follow/unfollow)
/// - Notification settings
/// - Muted sources and keywords
///
/// ## Data Flow
/// 1. Views dispatch `SettingsDomainAction` via `dispatch(action:)`
/// 2. Interactor processes actions and updates `SettingsDomainState`
/// 3. State changes are published via `statePublisher`
///
/// ## Dependencies
/// - `SettingsService`: Manages preference persistence
/// - `NotificationService`: Manages OS notification permissions and registration
final class SettingsDomainInteractor: CombineInteractor {
    typealias DomainState = SettingsDomainState
    typealias DomainAction = SettingsDomainAction

    private let settingsService: SettingsService
    private let notificationService: NotificationService
    private let analyticsService: AnalyticsService?
    private let storeKitService: StoreKitService?
    private let stateSubject = CurrentValueSubject<DomainState, Never>(.initial)
    private var cancellables = Set<AnyCancellable>()

    var statePublisher: AnyPublisher<DomainState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var currentState: DomainState {
        stateSubject.value
    }

    init(serviceLocator: ServiceLocator) {
        do {
            settingsService = try serviceLocator.retrieve(SettingsService.self)
        } catch {
            Logger.shared.service("Failed to retrieve SettingsService: \(error)", level: .warning)
            settingsService = LiveSettingsService(storageService: LiveStorageService(enableCloudKit: false))
        }

        notificationService = (try? serviceLocator.retrieve(NotificationService.self))
            ?? LiveNotificationService.shared
        analyticsService = try? serviceLocator.retrieve(AnalyticsService.self)
        storeKitService = try? serviceLocator.retrieve(StoreKitService.self)

        NotificationCenter.default.publisher(for: .cloudSyncDidComplete)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleCloudSyncCompletion()
            }
            .store(in: &cancellables)
    }

    // swiftlint:disable:next cyclomatic_complexity
    func dispatch(action: DomainAction) {
        switch action {
        case .loadPreferences:
            loadPreferences()
        case let .toggleNotifications(enabled):
            Task { @MainActor in await toggleNotifications(enabled) }
        case let .toggleBreakingNews(enabled):
            toggleBreakingNews(enabled)
        case let .toggleMorningBriefing(enabled):
            Task { @MainActor in await toggleMorningBriefing(enabled) }
        case let .changeMorningBriefingTime(hour, minute):
            Task { @MainActor in await changeMorningBriefingTime(hour: hour, minute: minute) }
        case let .changeMorningBriefingArticleCount(count):
            changeMorningBriefingArticleCount(count)
        case let .changeLanguage(language):
            changeLanguage(language)
        case .addMutedSource, .removeMutedSource, .addMutedKeyword, .removeMutedKeyword:
            handleMutedContentAction(action)
        case .setShowSignOutConfirmation,
             .setShowDeleteAccountConfirmation,
             .setIsDeletingAccount,
             .setNewMutedSource,
             .setNewMutedKeyword:
            handleUIStateAction(action)
        case .dismissError:
            updateState { state in state.error = nil }
        case let .setError(message):
            updateState { state in state.error = message }
        case .dismissNotificationsDeniedAlert:
            updateState { state in state.showNotificationsDeniedAlert = false }
        case .syncNotificationStatus:
            Task { @MainActor in await syncNotificationStatus() }
        }
    }

    private func handleMutedContentAction(_ action: DomainAction) {
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

    private func handleUIStateAction(_ action: DomainAction) {
        updateState { state in
            switch action {
            case let .setShowSignOutConfirmation(show):
                state.showSignOutConfirmation = show
            case let .setShowDeleteAccountConfirmation(show):
                state.showDeleteAccountConfirmation = show
            case let .setIsDeletingAccount(isDeleting):
                state.isDeletingAccount = isDeleting
            case let .setNewMutedSource(source):
                state.newMutedSource = source
            case let .setNewMutedKeyword(keyword):
                state.newMutedKeyword = keyword
            default:
                break
            }
        }
    }

    private func handleCloudSyncCompletion() {
        settingsService.fetchPreferences()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.analyticsService?.recordError(error)
                }
            } receiveValue: { [weak self] preferences in
                self?.updateState { state in
                    state.preferences = preferences
                }
                NotificationCenter.default.post(name: .userPreferencesDidChange, object: nil)
            }
            .store(in: &cancellables)
    }

    private func loadPreferences() {
        analyticsService?.logEvent(.screenView(screen: .settings))

        updateState { state in
            state.isLoading = true
            state.error = nil
        }

        settingsService.fetchPreferences()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.analyticsService?.recordError(error)
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
                // Sync notification toggle with actual OS permission status
                self?.dispatch(action: .syncNotificationStatus)
            }
            .store(in: &cancellables)
    }

    private func toggleNotifications(_ enabled: Bool) async {
        if enabled {
            let status = await notificationService.authorizationStatus()
            switch status {
            case .notDetermined:
                do {
                    let granted = try await notificationService.requestAuthorization()
                    var preferences = currentState.preferences
                    preferences.notificationsEnabled = granted
                    savePreferences(preferences)
                } catch {
                    updateState { state in
                        state.preferences.notificationsEnabled = false
                        state.error = error.localizedDescription
                    }
                }
            case .authorized, .provisional:
                await notificationService.registerForRemoteNotifications()
                var preferences = currentState.preferences
                preferences.notificationsEnabled = true
                savePreferences(preferences)
            case .denied:
                updateState { state in
                    state.preferences.notificationsEnabled = false
                    state.showNotificationsDeniedAlert = true
                }
            }
        } else {
            await notificationService.unregisterForRemoteNotifications()
            var preferences = currentState.preferences
            preferences.notificationsEnabled = false
            savePreferences(preferences)
        }
    }

    private func syncNotificationStatus() async {
        let status = await notificationService.authorizationStatus()
        let isOSAuthorized = status == .authorized || status == .provisional
        if currentState.preferences.notificationsEnabled, !isOSAuthorized {
            var preferences = currentState.preferences
            preferences.notificationsEnabled = false
            savePreferences(preferences)
        }
    }

    private func toggleBreakingNews(_ enabled: Bool) {
        var preferences = currentState.preferences
        preferences.breakingNewsNotifications = enabled
        savePreferences(preferences)
    }

    private func toggleMorningBriefing(_ enabled: Bool) async {
        guard enabled else {
            notificationService.cancelMorningBriefingNotification()
            var preferences = currentState.preferences
            preferences.morningBriefingEnabled = false
            savePreferences(preferences)
            return
        }

        // Defense-in-depth: re-verify the Premium entitlement at the service
        // boundary, not just in the view layer, in case a tampered client
        // dispatches `.toggleMorningBriefing(true)` directly.
        guard storeKitService?.isPremium != false else {
            Logger.shared.service(
                "Morning Briefing enable blocked: Premium entitlement not active",
                level: .warning
            )
            return
        }

        let status = await notificationService.authorizationStatus()
        switch status {
        case .notDetermined:
            do {
                let granted = try await notificationService.requestAuthorization()
                guard granted else {
                    updateState { state in state.showNotificationsDeniedAlert = true }
                    return
                }
                await scheduleAndSaveMorningBriefing()
            } catch {
                updateState { state in state.error = error.localizedDescription }
            }
        case .authorized, .provisional:
            await scheduleAndSaveMorningBriefing()
        case .denied:
            updateState { state in state.showNotificationsDeniedAlert = true }
        }
    }

    private func scheduleAndSaveMorningBriefing() async {
        var preferences = currentState.preferences
        preferences.morningBriefingEnabled = true
        await notificationService.scheduleMorningBriefingNotification(
            hour: preferences.morningBriefingHour,
            minute: preferences.morningBriefingMinute
        )
        savePreferences(preferences)
    }

    private func changeMorningBriefingTime(hour: Int, minute: Int) async {
        var preferences = currentState.preferences
        preferences.morningBriefingHour = hour
        preferences.morningBriefingMinute = minute
        if preferences.morningBriefingEnabled {
            await notificationService.scheduleMorningBriefingNotification(hour: hour, minute: minute)
        }
        savePreferences(preferences)
    }

    private func changeMorningBriefingArticleCount(_ count: Int) {
        var preferences = currentState.preferences
        preferences.morningBriefingArticleCount = count
        savePreferences(preferences)
    }

    private func changeLanguage(_ language: String) {
        var preferences = currentState.preferences
        preferences.preferredLanguage = language
        savePreferences(preferences)

        Task { @MainActor in
            AppLocalization.shared.updateLanguage(language)
        }
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
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.analyticsService?.recordError(error)
                    self?.updateState { state in
                        state.isSaving = false
                        state.error = error.localizedDescription
                    }
                }
            } receiveValue: { [weak self] in
                self?.updateState { state in
                    state.isSaving = false
                }
                // Notify other components (e.g., Home) that preferences changed
                NotificationCenter.default.post(name: .userPreferencesDidChange, object: nil)
            }
            .store(in: &cancellables)
    }

    private func updateState(_ transform: (inout DomainState) -> Void) {
        var state = stateSubject.value
        transform(&state)
        stateSubject.send(state)
    }
}

enum SettingsDomainAction: Equatable {
    case loadPreferences
    case toggleNotifications(Bool)
    case toggleBreakingNews(Bool)
    case toggleMorningBriefing(Bool)
    case changeMorningBriefingTime(hour: Int, minute: Int)
    case changeMorningBriefingArticleCount(Int)
    case changeLanguage(String)
    case addMutedSource(String)
    case removeMutedSource(String)
    case addMutedKeyword(String)
    case removeMutedKeyword(String)
    case setShowSignOutConfirmation(Bool)
    case setShowDeleteAccountConfirmation(Bool)
    case setIsDeletingAccount(Bool)
    case setNewMutedSource(String)
    case setNewMutedKeyword(String)
    case dismissError
    case setError(String?)
    case dismissNotificationsDeniedAlert
    case syncNotificationStatus
}
