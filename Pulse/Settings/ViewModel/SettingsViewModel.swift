import Combine
import Foundation

final class SettingsViewModel: CombineViewModel, ObservableObject {
    typealias ViewState = SettingsViewState
    typealias ViewEvent = SettingsViewEvent

    @Published private(set) var viewState: SettingsViewState = .initial
    @Published var newMutedSource: String = ""
    @Published var newMutedKeyword: String = ""

    private let serviceLocator: ServiceLocator
    private let interactor: SettingsDomainInteractor
    private let themeManager: ThemeManager
    private var cancellables = Set<AnyCancellable>()

    init(
        serviceLocator: ServiceLocator,
        themeManager: ThemeManager = .shared
    ) {
        self.serviceLocator = serviceLocator
        interactor = SettingsDomainInteractor(serviceLocator: serviceLocator)
        self.themeManager = themeManager
        setupBindings()
    }

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
        case .onAddMutedSource:
            guard !newMutedSource.isEmpty else { return }
            interactor.dispatch(action: .addMutedSource(newMutedSource))
            newMutedSource = ""
        case let .onRemoveMutedSource(source):
            interactor.dispatch(action: .removeMutedSource(source))
        case .onAddMutedKeyword:
            guard !newMutedKeyword.isEmpty else { return }
            interactor.dispatch(action: .addMutedKeyword(newMutedKeyword))
            newMutedKeyword = ""
        case let .onRemoveMutedKeyword(keyword):
            interactor.dispatch(action: .removeMutedKeyword(keyword))
        case .onClearReadingHistory:
            interactor.dispatch(action: .setShowClearHistoryConfirmation(true))
        case .onConfirmClearHistory:
            interactor.dispatch(action: .clearReadingHistory)
        case .onCancelClearHistory:
            interactor.dispatch(action: .setShowClearHistoryConfirmation(false))
        }
    }

    private func setupBindings() {
        Publishers.CombineLatest3(
            interactor.statePublisher,
            themeManager.$isDarkMode,
            themeManager.$useSystemTheme
        )
        .map { state, isDarkMode, useSystemTheme in
            SettingsViewState(
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
                errorMessage: state.error
            )
        }
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
    var errorMessage: String?

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
            errorMessage: nil
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
    case onAddMutedSource
    case onRemoveMutedSource(String)
    case onAddMutedKeyword
    case onRemoveMutedKeyword(String)
    case onClearReadingHistory
    case onConfirmClearHistory
    case onCancelClearHistory
}
