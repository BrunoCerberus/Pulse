import Combine
import EntropyCore
import Foundation

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
        themeManager: ThemeManager = .shared,
        authenticationManager: AuthenticationManager = .shared
    ) {
        self.serviceLocator = serviceLocator
        interactor = SettingsDomainInteractor(serviceLocator: serviceLocator)
        self.themeManager = themeManager
        self.authenticationManager = authenticationManager
        authService = try? serviceLocator.retrieve(AuthService.self)
        setupBindings()
    }

    // swiftlint:disable:next cyclomatic_complexity
    func handle(event: SettingsViewEvent) {
        switch event {
        case .onAppear:
            interactor.dispatch(action: .loadPreferences)
        case let .onToggleTopic(topic):
            interactor.dispatch(action: .toggleTopic(topic))
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
        case .onClearReadingHistory:
            interactor.dispatch(action: .setShowClearHistoryConfirmation(true))
        case .onConfirmClearHistory:
            interactor.dispatch(action: .clearReadingHistory)
        case .onCancelClearHistory:
            interactor.dispatch(action: .setShowClearHistoryConfirmation(false))
        case .onSignOutTapped:
            interactor.dispatch(action: .setShowSignOutConfirmation(true))
        case .onConfirmSignOut:
            handleSignOut()
        case .onCancelSignOut:
            interactor.dispatch(action: .setShowSignOutConfirmation(false))
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
        Publishers.CombineLatest3(
            interactor.statePublisher,
            themeManager.$isDarkMode.removeDuplicates(),
            themeManager.$useSystemTheme.removeDuplicates()
        )
        .combineLatest(authenticationManager.authStatePublisher.removeDuplicates())
        .map { combined, authState in
            let (state, isDarkMode, useSystemTheme) = combined
            let currentUser: AuthUser? = {
                if case let .authenticated(user) = authState {
                    return user
                }
                return nil
            }()
            return SettingsViewState(
                followedTopics: state.preferences.followedTopics,
                allTopics: NewsCategory.allCases,
                mutedSources: state.preferences.mutedSources,
                mutedKeywords: state.preferences.mutedKeywords,
                notificationsEnabled: state.preferences.notificationsEnabled,
                breakingNewsEnabled: state.preferences.breakingNewsNotifications,
                isDarkMode: isDarkMode,
                useSystemTheme: useSystemTheme,
                isLoading: state.isLoading,
                showClearHistoryConfirmation: state.showClearHistoryConfirmation,
                showSignOutConfirmation: state.showSignOutConfirmation,
                currentUser: currentUser,
                errorMessage: state.error,
                newMutedSource: state.newMutedSource,
                newMutedKeyword: state.newMutedKeyword
            )
        }
        .removeDuplicates()
        .receive(on: DispatchQueue.main)
        .assign(to: &$viewState)
    }
}

struct SettingsViewState: Equatable {
    var followedTopics: [NewsCategory]
    var allTopics: [NewsCategory]
    var mutedSources: [String]
    var mutedKeywords: [String]
    var notificationsEnabled: Bool
    var breakingNewsEnabled: Bool
    var isDarkMode: Bool
    var useSystemTheme: Bool
    var isLoading: Bool
    var showClearHistoryConfirmation: Bool
    var showSignOutConfirmation: Bool
    var currentUser: AuthUser?
    var errorMessage: String?
    var newMutedSource: String
    var newMutedKeyword: String

    static var initial: SettingsViewState {
        SettingsViewState(
            followedTopics: [],
            allTopics: NewsCategory.allCases,
            mutedSources: [],
            mutedKeywords: [],
            notificationsEnabled: true,
            breakingNewsEnabled: true,
            isDarkMode: false,
            useSystemTheme: true,
            isLoading: false,
            showClearHistoryConfirmation: false,
            showSignOutConfirmation: false,
            currentUser: nil,
            errorMessage: nil,
            newMutedSource: "",
            newMutedKeyword: ""
        )
    }
}

enum SettingsViewEvent: Equatable {
    case onAppear
    case onToggleTopic(NewsCategory)
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
    case onClearReadingHistory
    case onConfirmClearHistory
    case onCancelClearHistory
    case onSignOutTapped
    case onConfirmSignOut
    case onCancelSignOut
}
