import Combine
import EntropyCore
import Foundation
import UIKit

@MainActor
// swiftlint:disable:next type_body_length
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
                    guard let self else { return }
                    // Capture deps strongly into locals BEFORE spawning the
                    // Task. After Firebase sign-out, AuthenticationManager
                    // flips state and RootView tears down the Coordinator;
                    // SettingsViewModel can be released before the Task body
                    // ever runs. A `[weak self]` Task here would silently
                    // skip the cleanup — exactly the orphan-PII bug this PR
                    // is supposed to prevent.
                    let serviceLocator = self.serviceLocator
                    let themeManager = self.themeManager
                    let interactor = self.interactor
                    Task { @MainActor in
                        let failures = await Self.clearAllUserData(
                            serviceLocator: serviceLocator,
                            themeManager: themeManager
                        )
                        if !failures.isEmpty {
                            Self.surfacePartialCleanupFailure(
                                key: "account.sign_out.cleanup_partial_failure",
                                interactor: interactor
                            )
                        }
                    }
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
                    if case let .failure(error) = completion {
                        // Failure path clears the spinner immediately; success
                        // path defers the clear until cleanup finishes so the
                        // user isn't dropped back to Settings mid-wipe.
                        self?.interactor.dispatch(action: .setIsDeletingAccount(false))
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
                    guard let self else { return }
                    self.analyticsService?.logEvent(.deleteAccount)
                    // Same rationale as `handleSignOut`: capture deps strongly
                    // so cleanup doesn't get cancelled by the auth-state flip
                    // releasing this view model. Worse here than sign-out
                    // because the Firebase account is already gone — leaving
                    // local data orphan would be a direct LGPD / GDPR
                    // right-to-erasure violation.
                    let serviceLocator = self.serviceLocator
                    let themeManager = self.themeManager
                    let interactor = self.interactor
                    Task { @MainActor in
                        let failures = await Self.clearAllUserData(
                            serviceLocator: serviceLocator,
                            themeManager: themeManager
                        )
                        interactor.dispatch(action: .setIsDeletingAccount(false))
                        if !failures.isEmpty {
                            Self.surfacePartialCleanupFailure(
                                key: "account.delete.cleanup_partial_failure",
                                interactor: interactor
                            )
                        }
                    }
                }
            )
            .store(in: &cancellables)
    }

    /// Writes the partial-cleanup error message both to the in-memory
    /// interactor state (best-effort — Settings may still be mounted) AND
    /// to UserDefaults under `pendingCleanupErrorKey` so `SignInView` can
    /// surface it after the auth-state flip has dismounted Settings.
    ///
    /// Without the UserDefaults persistence the alert is dead code on the
    /// happy-path: the moment `authService.signOut()` returns,
    /// `AuthenticationManager` publishes `.unauthenticated`, `RootView`
    /// swaps `CoordinatorView` → `SignInView`, and the SwiftUI binding
    /// that would have presented the alert is gone before this code runs.
    @MainActor
    private static func surfacePartialCleanupFailure(
        key: String,
        interactor: SettingsDomainInteractor,
        defaults: UserDefaults = .standard
    ) {
        let message = AppLocalization.shared.localized(key)
        defaults.set(message, forKey: pendingCleanupErrorKey)
        interactor.dispatch(action: .setError(message))
    }

    /// UserDefaults key carrying the most recent partial-cleanup failure
    /// message. Read + cleared by `SignInView` so the user actually sees
    /// the error after auth-state flip.
    static let pendingCleanupErrorKey = "pulse.pendingCleanupErrorMessage"

    private static func defaultViewControllerProvider() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first(where: \.isKeyWindow)?.rootViewController
    }

    // swiftlint:disable function_body_length cyclomatic_complexity

    /// Runs every cleanup step sequentially and returns the list of step
    /// identifiers that failed. Caller surfaces the list to the user.
    ///
    /// `static` — and accepts every dependency it touches as a parameter —
    /// so the caller can spawn a `Task` that holds the deps strongly
    /// without capturing `self`. If a `[weak self] Task { … }` wrapper
    /// were used here instead, the auth-state flip after Firebase
    /// sign-out / delete would release `SettingsViewModel` before the
    /// Task body runs, the inner `guard let self` would fail, and the
    /// cleanup would silently be skipped — exactly the orphan-PII bug
    /// this method is supposed to prevent.
    ///
    /// The previous implementation also fired three async cleanup tasks
    /// in parallel and returned before any of them had a chance to
    /// complete. Awaiting each step sequentially closes the
    /// force-quit-between-delete-and-wipe window on top of the dealloc
    /// fix above.
    @MainActor
    static func clearAllUserData(
        serviceLocator: ServiceLocator,
        themeManager: ThemeManager
    ) async -> [String] {
        var failures: [String] = []

        // 0. End any active TTS Live Activity first so the article title
        //    doesn't linger on the Lock Screen after the user signs out.
        // NOTE: ActivityKit dismissal is OS-mediated and inherently
        // asynchronous — `end()` returns once we've asked the system to
        // dismiss, but a force-quit between that call and the system
        // actually clearing the Live Activity could leave it visible
        // briefly. This is the best we can do from the app side.
        TTSLiveActivityController.shared.end()

        // 1. Clear SwiftData (bookmarks, preferences, reading history). Services
        //    aren't `Sendable`; box them across the `await` per the
        //    CombineAsyncBridge convention used throughout the app.
        if let storageService = try? serviceLocator.retrieve(StorageService.self) {
            let service = UncheckedSendableBox(value: storageService)
            do {
                try await service.value.clearAllUserData()
            } catch {
                Logger.shared.service("Failed to clear user data on sign-out: \(error)", level: .error)
                failures.append("storage")
            }
        }

        // 1a. Clear personalization profile (CloudKit-synced) and pending
        //     engagement events (device-local).
        if let profileService = try? serviceLocator.retrieve(InterestProfileService.self) {
            let service = UncheckedSendableBox(value: profileService)
            do {
                try await service.value.resetProfile()
            } catch {
                Logger.shared.service(
                    "Failed to clear interest profile on sign-out: \(error)",
                    level: .warning
                )
                failures.append("interest_profile")
            }
        }
        if let engagementService = try? serviceLocator.retrieve(EngagementEventsService.self) {
            let service = UncheckedSendableBox(value: engagementService)
            do {
                try await service.value.clearAll()
            } catch {
                Logger.shared.service(
                    "Failed to clear engagement queue on sign-out: \(error)",
                    level: .warning
                )
                failures.append("engagement")
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
            LiveNotificationService.keychainService,
        ])

        // 9. Best-effort: delete the user's private CloudKit record zone so a
        //    reinstall on the same iCloud account doesn't restore prior bookmarks
        //    / reading history. Fire-and-forget; failures only log.
        SignOutCleanup.deletePrivateCloudKitZones(LiveStorageService.cloudKitContainerIdentifier)

        if failures.isEmpty {
            Logger.shared.service("Cleared all local user data", level: .info)
        } else {
            Logger.shared.service(
                "Cleared local user data with failures: \(failures.joined(separator: ", "))",
                level: .warning
            )
        }
        return failures
    }

    // swiftlint:enable function_body_length cyclomatic_complexity

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
