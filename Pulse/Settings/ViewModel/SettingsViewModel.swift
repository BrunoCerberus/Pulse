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
    private let appLockManager: AppLockManager
    private var authService: AuthService?
    private var cancellables = Set<AnyCancellable>()

    init(
        serviceLocator: ServiceLocator,
        themeManager: ThemeManager? = nil,
        authenticationManager: AuthenticationManager? = nil,
        appLockManager: AppLockManager? = nil
    ) {
        self.serviceLocator = serviceLocator
        interactor = SettingsDomainInteractor(serviceLocator: serviceLocator)
        self.themeManager = themeManager ?? .shared
        self.authenticationManager = authenticationManager ?? .shared
        self.appLockManager = appLockManager ?? .shared
        authService = try? serviceLocator.retrieve(AuthService.self)
        setupBindings()
    }

    func handle(event: SettingsViewEvent) {
        switch event {
        case .onAppear:
            interactor.dispatch(action: .loadPreferences)
        case let .onToggleNotifications(enabled):
            interactor.dispatch(action: .toggleNotifications(enabled))
        case let .onToggleBreakingNews(enabled):
            interactor.dispatch(action: .toggleBreakingNews(enabled))
        case let .onToggleDarkMode(enabled):
            themeManager.isDarkMode = enabled
        case let .onToggleSystemTheme(enabled):
            themeManager.useSystemTheme = enabled
        case let .onNewMutedSourceChanged(source):
            interactor.dispatch(action: .setNewMutedSource(source))
        case .onAddMutedSource:
            interactor.dispatch(action: .addMutedSource(interactor.currentState.newMutedSource))
        case let .onRemoveMutedSource(source):
            interactor.dispatch(action: .removeMutedSource(source))
        case let .onNewMutedKeywordChanged(keyword):
            interactor.dispatch(action: .setNewMutedKeyword(keyword))
        case .onAddMutedKeyword:
            interactor.dispatch(action: .addMutedKeyword(interactor.currentState.newMutedKeyword))
        case let .onRemoveMutedKeyword(keyword):
            interactor.dispatch(action: .removeMutedKeyword(keyword))
        case .onSignOutTapped:
            interactor.dispatch(action: .setShowSignOutConfirmation(true))
        case .onConfirmSignOut:
            handleSignOut()
        case .onCancelSignOut:
            interactor.dispatch(action: .setShowSignOutConfirmation(false))
        case let .onToggleBiometric(enabled):
            if enabled {
                appLockManager.enableBiometric()
            } else {
                appLockManager.disableBiometric()
            }
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
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }

    private func setupBindings() {
        // Combine all state sources including biometric preferences
        Publishers.CombineLatest(
            Publishers.CombineLatest4(
                interactor.statePublisher,
                themeManager.$isDarkMode.removeDuplicates(),
                themeManager.$useSystemTheme.removeDuplicates(),
                authenticationManager.authStatePublisher.removeDuplicates()
            ),
            appLockManager.$isBiometricEnabled.removeDuplicates()
        )
        // Debounce rapid changes to prevent excessive UI updates during theme toggling
        .debounce(for: .milliseconds(16), scheduler: DispatchQueue.main)
        .map { [appLockManager] combined, isBiometricEnabled in
            let (state, isDarkMode, useSystemTheme, authState) = combined
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
                newMutedSource: state.newMutedSource,
                newMutedKeyword: state.newMutedKeyword,
                isBiometricEnabled: isBiometricEnabled,
                isBiometricAvailable: appLockManager.isBiometricAvailable,
                biometricName: appLockManager.biometricName
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
    var newMutedSource: String
    var newMutedKeyword: String
    var isBiometricEnabled: Bool
    var isBiometricAvailable: Bool
    var biometricName: String

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
            newMutedSource: "",
            newMutedKeyword: "",
            isBiometricEnabled: false,
            isBiometricAvailable: false,
            biometricName: "Face ID"
        )
    }
}

enum SettingsViewEvent: Equatable {
    case onAppear
    case onToggleNotifications(Bool)
    case onToggleBreakingNews(Bool)
    case onToggleDarkMode(Bool)
    case onToggleSystemTheme(Bool)
    case onNewMutedSourceChanged(String)
    case onAddMutedSource
    case onRemoveMutedSource(String)
    case onNewMutedKeywordChanged(String)
    case onAddMutedKeyword
    case onRemoveMutedKeyword(String)
    case onSignOutTapped
    case onConfirmSignOut
    case onCancelSignOut
    case onToggleBiometric(Bool)
}
