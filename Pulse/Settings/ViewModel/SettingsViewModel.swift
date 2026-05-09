import Combine
import EntropyCore
import Foundation
import UIKit

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
    private let viewControllerProvider: () -> UIViewController?
    private var authService: AuthService?
    private var analyticsService: AnalyticsService?
    private var cancellables = Set<AnyCancellable>()

    init(
        serviceLocator: ServiceLocator,
        themeManager: ThemeManager? = nil,
        authenticationManager: AuthenticationManager? = nil,
        viewControllerProvider: (() -> UIViewController?)? = nil
    ) {
        self.serviceLocator = serviceLocator
        interactor = SettingsDomainInteractor(serviceLocator: serviceLocator)
        self.themeManager = themeManager ?? .shared
        self.authenticationManager = authenticationManager ?? .shared
        self.viewControllerProvider = viewControllerProvider ?? Self.defaultViewControllerProvider
        authService = try? serviceLocator.retrieve(AuthService.self)
        analyticsService = try? serviceLocator.retrieve(AnalyticsService.self)
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
        case .onDeleteAccountTapped:
            interactor.dispatch(action: .setShowDeleteAccountConfirmation(true))
        case .onConfirmDeleteAccount:
            handleDeleteAccount()
        case .onCancelDeleteAccount:
            interactor.dispatch(action: .setShowDeleteAccountConfirmation(false))
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
                    self?.clearAllUserData()
                }
            )
            .store(in: &cancellables)
    }

    private func handleDeleteAccount() {
        guard let authService, let viewController = viewControllerProvider() else { return }
        interactor.dispatch(action: .setShowDeleteAccountConfirmation(false))
        interactor.dispatch(action: .setIsDeletingAccount(true))

        authService.deleteAccount(presenting: viewController)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.interactor.dispatch(action: .setIsDeletingAccount(false))
                    if case let .failure(error) = completion {
                        // Silently swallow user-cancelled re-auth; show everything else.
                        if case AuthError.signInCancelled = error {
                            Logger.shared.service("Account deletion cancelled by user", level: .info)
                        } else {
                            let message = "Account deletion failed: \(error.localizedDescription)"
                            Logger.shared.service(message, level: .error)
                            self?.analyticsService?.recordError(error)
                        }
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.analyticsService?.logEvent(.deleteAccount)
                    self?.clearAllUserData()
                }
            )
            .store(in: &cancellables)
    }

    private static func defaultViewControllerProvider() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first(where: \.isKeyWindow)?.rootViewController
    }

    private func clearAllUserData() {
        // 1. Clear SwiftData (bookmarks, preferences, reading history)
        if let storageService = try? serviceLocator.retrieve(StorageService.self) {
            let service = UncheckedSendableBox(value: storageService)
            Task {
                do {
                    try await service.value.clearAllUserData()
                } catch {
                    Logger.shared.service("Failed to clear user data on sign-out: \(error)", level: .error)
                }
            }
        }

        // 1a. Clear personalization profile (CloudKit-synced) and pending
        //     engagement events (device-local). Best-effort — failures here
        //     don't block the rest of sign-out cleanup.
        if let profileService = try? serviceLocator.retrieve(InterestProfileService.self) {
            let service = UncheckedSendableBox(value: profileService)
            Task {
                do {
                    try await service.value.resetProfile()
                } catch {
                    Logger.shared.service(
                        "Failed to clear interest profile on sign-out: \(error)",
                        level: .warning
                    )
                }
            }
        }
        if let engagementService = try? serviceLocator.retrieve(EngagementEventsService.self) {
            let service = UncheckedSendableBox(value: engagementService)
            Task {
                do {
                    try await service.value.clearAll()
                } catch {
                    Logger.shared.service(
                        "Failed to clear engagement queue on sign-out: \(error)",
                        level: .warning
                    )
                }
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

        // 7. Clear widget shared data and any URLs queued by the Share Extension.
        let appGroupDefaults = UserDefaults(suiteName: "group.com.bruno.Pulse-News")
        appGroupDefaults?.removeObject(forKey: "shared_articles")
        appGroupDefaults?.removeObject(forKey: SharedURLQueue.queueKey)

        // 8. Wipe every Keychain item this app uses. `SignOutCleanup` deletes
        //    every `kSecAttrService` entry directly so we don't depend on the
        //    per-key API knowing which keys exist.
        SignOutCleanup.wipeKeychain(services: [
            LiveAppLockService.keychainService,
            APIKeysProvider.keychainService,
        ])

        // 9. Best-effort: delete the user's private CloudKit record zone so a
        //    reinstall on the same iCloud account doesn't restore prior bookmarks
        //    / reading history. Fire-and-forget; failures only log.
        SignOutCleanup.deletePrivateCloudKitZones(LiveStorageService.cloudKitContainerIdentifier)

        Logger.shared.service("Cleared all local user data", level: .info)
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
                showDeleteAccountConfirmation: state.showDeleteAccountConfirmation,
                isDeletingAccount: state.isDeletingAccount,
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
    var showDeleteAccountConfirmation: Bool
    var isDeletingAccount: Bool
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
            showDeleteAccountConfirmation: false,
            isDeletingAccount: false,
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
    case onDeleteAccountTapped
    case onConfirmDeleteAccount
    case onCancelDeleteAccount
    case onDismissError
    case onDismissNotificationsDeniedAlert
}
