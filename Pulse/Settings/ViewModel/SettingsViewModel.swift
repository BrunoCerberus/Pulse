import Combine
import EntropyCore
import Foundation

/// ViewModel for the Settings screen.
///
/// Implements `CombineViewModel` to manage user preferences and app settings.
/// Combines state from multiple sources: interactor, ThemeManager, and AuthenticationManager.
///
/// ## Features
/// - Topic management (follow/unfollow)
/// - Notification settings
/// - Dark mode and system theme toggle
/// - Muted sources and keywords
/// - Account management (sign out)
@MainActor
final class SettingsViewModel: CombineViewModel, ObservableObject {
    typealias ViewState = SettingsViewState
    typealias ViewEvent = SettingsViewEvent

    @Published private(set) var viewState: SettingsViewState = .initial

    private let serviceLocator: ServiceLocator
    private let interactor: SettingsDomainInteractor
    private let themeManager: ThemeManager
    private let authenticationManager: AuthenticationManager
    private var authService: AuthService?
    private var cancellables = Set<AnyCancellable>()

    init(
        serviceLocator: ServiceLocator,
        themeManager: ThemeManager? = nil,
        authenticationManager: AuthenticationManager? = nil
    ) {
        self.serviceLocator = serviceLocator
        interactor = SettingsDomainInteractor(serviceLocator: serviceLocator)
        self.themeManager = themeManager ?? .shared
        self.authenticationManager = authenticationManager ?? .shared
        authService = try? serviceLocator.retrieve(AuthService.self)
        setupBindings()
    }

    func handle(event: SettingsViewEvent) {
        if handleAppearanceAndSignOutEvents(event) {
            return
        }
        if handleThemeEvents(event) {
            return
        }
        if handleMutedSourceEvents(event) {
            return
        }
        if handleMutedKeywordEvents(event) {
            return
        }
        handleNotificationEvents(event)
    }

    @discardableResult
    private func handleAppearanceAndSignOutEvents(_ event: SettingsViewEvent) -> Bool {
        switch event {
        case .onAppear:
            interactor.dispatch(action: .loadPreferences)
        case .onSignOutTapped:
            interactor.dispatch(action: .setShowSignOutConfirmation(true))
        case .onConfirmSignOut:
            handleSignOut()
        case .onCancelSignOut:
            interactor.dispatch(action: .setShowSignOutConfirmation(false))
        case .onDismissError:
            interactor.dispatch(action: .dismissError)
        case .onDismissNotificationsDeniedAlert:
            interactor.dispatch(action: .dismissNotificationsDeniedAlert)
        default:
            return false
        }
        return true
    }

    @discardableResult
    private func handleThemeEvents(_ event: SettingsViewEvent) -> Bool {
        switch event {
        case let .onToggleDarkMode(enabled):
            themeManager.isDarkMode = enabled
        case let .onToggleSystemTheme(enabled):
            themeManager.useSystemTheme = enabled
        default:
            return false
        }
        return true
    }

    @discardableResult
    private func handleMutedSourceEvents(_ event: SettingsViewEvent) -> Bool {
        switch event {
        case let .onNewMutedSourceChanged(source):
            interactor.dispatch(action: .setNewMutedSource(source))
        case .onAddMutedSource:
            interactor.dispatch(action: .addMutedSource(interactor.currentState.newMutedSource))
        case let .onRemoveMutedSource(source):
            interactor.dispatch(action: .removeMutedSource(source))
        default:
            return false
        }
        return true
    }

    @discardableResult
    private func handleMutedKeywordEvents(_ event: SettingsViewEvent) -> Bool {
        switch event {
        case let .onNewMutedKeywordChanged(keyword):
            interactor.dispatch(action: .setNewMutedKeyword(keyword))
        case .onAddMutedKeyword:
            interactor.dispatch(action: .addMutedKeyword(interactor.currentState.newMutedKeyword))
        case let .onRemoveMutedKeyword(keyword):
            interactor.dispatch(action: .removeMutedKeyword(keyword))
        default:
            return false
        }
        return true
    }

    private func handleNotificationEvents(_ event: SettingsViewEvent) {
        switch event {
        case let .onToggleNotifications(enabled):
            interactor.dispatch(action: .toggleNotifications(enabled))
        case let .onToggleBreakingNews(enabled):
            interactor.dispatch(action: .toggleBreakingNews(enabled))
        case let .onLanguageChanged(language):
            interactor.dispatch(action: .changeLanguage(language))
        default:
            break
        }
    }

    private func handleSignOut() {
        guard let authService else { return }
        authService.signOut()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.interactor.dispatch(action: .setShowSignOutConfirmation(false))
                    if case let .failure(error) = completion {
                        Logger.shared.service("Sign out failed: \(error.localizedDescription)", level: .error)
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.clearUserDataOnSignOut()
                }
            )
            .store(in: &cancellables)
    }

    private func clearUserDataOnSignOut() {
        // 1. Clear SwiftData (bookmarks, preferences, reading history)
        if let storageService = try? serviceLocator.retrieve(StorageService.self) {
            Task {
                try? await storageService.clearAllUserData()
            }
        }

        // 2. Clear news and media caches (L1 + L2)
        if let newsService = try? serviceLocator.retrieve(NewsService.self) {
            (newsService as? CachingNewsService)?.invalidateAllCaches()
        }
        if let mediaService = try? serviceLocator.retrieve(MediaService.self) {
            (mediaService as? CachingMediaService)?.invalidateAllCaches()
        }

        // 3. Clear app lock settings
        if let appLockService = try? serviceLocator.retrieve(AppLockService.self) {
            appLockService.isEnabled = false
            appLockService.hasPromptedFaceID = false
        }

        // 4. Clear recent searches
        if let searchService = try? serviceLocator.retrieve(SearchService.self) {
            searchService.clearRecentSearches()
        }

        // 5. Clear UserDefaults preferences
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "pulse.hasCompletedOnboarding")
        defaults.removeObject(forKey: "pulse.isDarkMode")
        defaults.removeObject(forKey: "pulse.useSystemTheme")
        defaults.removeObject(forKey: "pulse.preferredLanguage")
        defaults.removeObject(forKey: "pulse.notificationsEnabled")
        defaults.removeObject(forKey: "pulse.deviceToken")

        // 6. Reset ThemeManager to system defaults
        themeManager.useSystemTheme = true
        themeManager.isDarkMode = false

        // 7. Clear widget shared data
        UserDefaults(suiteName: "group.com.bruno.Pulse-News")?.removeObject(forKey: "shared_articles")

        Logger.shared.service("User data cleared on sign-out", level: .info)
    }

    private func setupBindings() {
        // Use CombineLatest4 directly instead of nested combineLatest to reduce overhead
        Publishers.CombineLatest4(
            interactor.statePublisher,
            themeManager.$isDarkMode.removeDuplicates(),
            themeManager.$useSystemTheme.removeDuplicates(),
            authenticationManager.authStatePublisher.removeDuplicates()
        )
        // Debounce rapid changes to prevent excessive UI updates during theme toggling
        .debounce(for: .milliseconds(16), scheduler: DispatchQueue.main)
        .map { state, isDarkMode, useSystemTheme, authState in
            let currentUser: AuthUser? = {
                if case let .authenticated(user) = authState {
                    return user
                }
                return nil
            }()
            return SettingsViewState(
                mutedSources: state.preferences.mutedSources,
                mutedKeywords: state.preferences.mutedKeywords,
                notificationsEnabled: state.preferences.notificationsEnabled,
                breakingNewsEnabled: state.preferences.breakingNewsNotifications,
                isDarkMode: isDarkMode,
                useSystemTheme: useSystemTheme,
                isLoading: state.isLoading,
                showSignOutConfirmation: state.showSignOutConfirmation,
                currentUser: currentUser,
                errorMessage: state.error,
                showNotificationsDeniedAlert: state.showNotificationsDeniedAlert,
                newMutedSource: state.newMutedSource,
                newMutedKeyword: state.newMutedKeyword,
                selectedLanguage: state.preferences.preferredLanguage
            )
        }
        .removeDuplicates()
        .receive(on: DispatchQueue.main)
        .assign(to: &$viewState)
    }
}

struct SettingsViewState: Equatable {
    var mutedSources: [String]
    var mutedKeywords: [String]
    var notificationsEnabled: Bool
    var breakingNewsEnabled: Bool
    var isDarkMode: Bool
    var useSystemTheme: Bool
    var isLoading: Bool
    var showSignOutConfirmation: Bool
    var currentUser: AuthUser?
    var errorMessage: String?
    var showNotificationsDeniedAlert: Bool
    var newMutedSource: String
    var newMutedKeyword: String
    var selectedLanguage: String

    static var initial: SettingsViewState {
        SettingsViewState(
            mutedSources: [],
            mutedKeywords: [],
            notificationsEnabled: true,
            breakingNewsEnabled: true,
            isDarkMode: false,
            useSystemTheme: true,
            isLoading: false,
            showSignOutConfirmation: false,
            currentUser: nil,
            errorMessage: nil,
            showNotificationsDeniedAlert: false,
            newMutedSource: "",
            newMutedKeyword: "",
            selectedLanguage: "en"
        )
    }
}

enum SettingsViewEvent: Equatable {
    case onAppear
    case onToggleNotifications(Bool)
    case onToggleBreakingNews(Bool)
    case onToggleDarkMode(Bool)
    case onToggleSystemTheme(Bool)
    case onLanguageChanged(String)
    case onNewMutedSourceChanged(String)
    case onAddMutedSource
    case onRemoveMutedSource(String)
    case onNewMutedKeywordChanged(String)
    case onAddMutedKeyword
    case onRemoveMutedKeyword(String)
    case onSignOutTapped
    case onConfirmSignOut
    case onCancelSignOut
    case onDismissError
    case onDismissNotificationsDeniedAlert
}
