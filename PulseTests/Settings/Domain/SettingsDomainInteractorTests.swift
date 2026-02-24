// swiftlint:disable file_length
import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

// MARK: - Test Helpers

@MainActor
// swiftlint:disable:next large_tuple
private func createSUT() -> (SettingsDomainInteractor, MockSettingsService, MockAnalyticsService) {
    let mockSettingsService = MockSettingsService()
    let mockAnalyticsService = MockAnalyticsService()
    let serviceLocator = ServiceLocator()
    serviceLocator.register(SettingsService.self, instance: mockSettingsService)
    serviceLocator.register(AnalyticsService.self, instance: mockAnalyticsService)
    return (SettingsDomainInteractor(serviceLocator: serviceLocator), mockSettingsService, mockAnalyticsService)
}

// MARK: - Initial State & Load Tests

@Suite("SettingsDomainInteractor State Tests")
@MainActor
struct SettingsInteractorStateTests {
    @Test("Initial state is correct")
    func initialState() {
        let (sut, _, _) = createSUT()
        let state = sut.currentState
        #expect(state.preferences == .default)
        #expect(!state.isLoading)
        #expect(!state.isSaving)
        #expect(state.error == nil)
    }

    @Test("Load preferences populates state")
    func loadPreferencesPopulatesState() async throws {
        let (sut, mock, _) = createSUT()
        mock.preferences = UserPreferences(
            followedTopics: [.technology, .science], followedSources: ["TechCrunch"],
            mutedSources: ["Spam"], mutedKeywords: ["clickbait"],
            preferredLanguage: "en", notificationsEnabled: true, breakingNewsNotifications: false
        )
        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 300_000_000)
        #expect(!sut.currentState.isLoading)
        #expect(sut.currentState.preferences == mock.preferences)
    }

    @Test("Load preferences sets loading state")
    func loadPreferencesSetsLoadingState() async throws {
        let (sut, _, _) = createSUT()
        var cancellables = Set<AnyCancellable>()
        var loadingStates: [Bool] = []
        sut.statePublisher.map(\.isLoading).sink { loadingStates.append($0) }.store(in: &cancellables)
        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 300_000_000)
        #expect(loadingStates.contains(true))
        #expect(loadingStates.last == false)
    }
}

// MARK: - Notification Tests

@Suite("SettingsDomainInteractor Notification Tests")
@MainActor
struct SettingsInteractorNotifyTests {
    @Test("Toggle notifications enables when disabled")
    func toggleNotificationsEnables() async throws {
        let (sut, mock, _) = createSUT()
        mock.preferences = UserPreferences(
            followedTopics: [], followedSources: [], mutedSources: [], mutedKeywords: [],
            preferredLanguage: "en", notificationsEnabled: false, breakingNewsNotifications: true
        )
        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 300_000_000)
        sut.dispatch(action: .toggleNotifications(true))
        try await Task.sleep(nanoseconds: 300_000_000)
        #expect(sut.currentState.preferences.notificationsEnabled)
    }

    @Test("Toggle notifications disables when enabled")
    func toggleNotificationsDisables() async throws {
        let (sut, mock, _) = createSUT()
        mock.preferences = .default
        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 300_000_000)
        sut.dispatch(action: .toggleNotifications(false))
        try await Task.sleep(nanoseconds: 300_000_000)
        #expect(!sut.currentState.preferences.notificationsEnabled)
    }

    @Test("Toggle breaking news enables when disabled")
    func toggleBreakingNewsEnables() async throws {
        let (sut, mock, _) = createSUT()
        mock.preferences = UserPreferences(
            followedTopics: [], followedSources: [], mutedSources: [], mutedKeywords: [],
            preferredLanguage: "en", notificationsEnabled: true, breakingNewsNotifications: false
        )
        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 300_000_000)
        sut.dispatch(action: .toggleBreakingNews(true))
        try await Task.sleep(nanoseconds: 300_000_000)
        #expect(sut.currentState.preferences.breakingNewsNotifications)
    }

    @Test("Toggle breaking news disables when enabled")
    func toggleBreakingNewsDisables() async throws {
        let (sut, mock, _) = createSUT()
        mock.preferences = .default
        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 300_000_000)
        sut.dispatch(action: .toggleBreakingNews(false))
        try await Task.sleep(nanoseconds: 300_000_000)
        #expect(!sut.currentState.preferences.breakingNewsNotifications)
    }
}

// MARK: - Language Tests

@Suite("SettingsDomainInteractor Language Tests")
@MainActor
struct SettingsInteractorLanguageTests {
    private let languageKey = "pulse.preferredLanguage"

    @Test("Change language updates preferences and AppLocalization")
    func changeLanguageUpdatesPreferencesAndLocalization() async throws {
        let defaults = UserDefaults.standard
        let previous = defaults.string(forKey: languageKey)
        defer {
            if let previous {
                defaults.set(previous, forKey: languageKey)
                AppLocalization.shared.updateLanguage(previous)
            } else {
                defaults.removeObject(forKey: languageKey)
                AppLocalization.shared.updateLanguage("en")
            }
        }

        let (sut, mock, _) = createSUT()
        mock.preferences = .default
        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 300_000_000)

        sut.dispatch(action: .changeLanguage("es"))
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(sut.currentState.preferences.preferredLanguage == "es")
        #expect(mock.preferences.preferredLanguage == "es")
        #expect(AppLocalization.shared.language == "es")
    }

    @Test("Change language persists to UserDefaults")
    func changeLanguagePersistsToUserDefaults() async throws {
        let defaults = UserDefaults.standard
        let previous = defaults.string(forKey: languageKey)
        defer {
            if let previous {
                defaults.set(previous, forKey: languageKey)
                AppLocalization.shared.updateLanguage(previous)
            } else {
                defaults.removeObject(forKey: languageKey)
                AppLocalization.shared.updateLanguage("en")
            }
        }

        let (sut, mock, _) = createSUT()
        mock.preferences = .default
        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 300_000_000)

        sut.dispatch(action: .changeLanguage("pt"))
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(defaults.string(forKey: languageKey) == "pt")
    }
}

// MARK: - Muted Content Tests

@Suite("SettingsDomainInteractor Muted Tests")
@MainActor
struct SettingsInteractorMutedTests {
    @Test("Add muted source appends to list")
    func addMutedSourceAppends() async throws {
        let (sut, mock, _) = createSUT()
        mock.preferences = .default
        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 300_000_000)
        sut.dispatch(action: .addMutedSource("Spam News"))
        try await Task.sleep(nanoseconds: 300_000_000)
        #expect(sut.currentState.preferences.mutedSources.contains("Spam News"))
    }

    @Test("Add muted source prevents duplicates")
    func addMutedSourcePreventsDuplicates() async throws {
        let (sut, mock, _) = createSUT()
        mock.preferences = UserPreferences(
            followedTopics: [], followedSources: [], mutedSources: ["Existing"],
            mutedKeywords: [], preferredLanguage: "en", notificationsEnabled: true, breakingNewsNotifications: true
        )
        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 300_000_000)
        let initialCount = sut.currentState.preferences.mutedSources.count
        sut.dispatch(action: .addMutedSource("Existing"))
        try await Task.sleep(nanoseconds: 300_000_000)
        #expect(sut.currentState.preferences.mutedSources.count == initialCount)
    }

    @Test("Remove muted source removes from list")
    func removeMutedSourceRemoves() async throws {
        let (sut, mock, _) = createSUT()
        mock.preferences = UserPreferences(
            followedTopics: [], followedSources: [], mutedSources: ["Source 1", "Source 2"],
            mutedKeywords: [], preferredLanguage: "en", notificationsEnabled: true, breakingNewsNotifications: true
        )
        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 300_000_000)
        sut.dispatch(action: .removeMutedSource("Source 1"))
        try await Task.sleep(nanoseconds: 300_000_000)
        #expect(!sut.currentState.preferences.mutedSources.contains("Source 1"))
        #expect(sut.currentState.preferences.mutedSources.contains("Source 2"))
    }

    @Test("Add muted keyword appends to list")
    func addMutedKeywordAppends() async throws {
        let (sut, mock, _) = createSUT()
        mock.preferences = .default
        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 300_000_000)
        sut.dispatch(action: .addMutedKeyword("clickbait"))
        try await Task.sleep(nanoseconds: 300_000_000)
        #expect(sut.currentState.preferences.mutedKeywords.contains("clickbait"))
    }

    @Test("Add muted keyword prevents duplicates")
    func addMutedKeywordPreventsDuplicates() async throws {
        let (sut, mock, _) = createSUT()
        mock.preferences = UserPreferences(
            followedTopics: [], followedSources: [], mutedSources: [], mutedKeywords: ["existing"],
            preferredLanguage: "en", notificationsEnabled: true, breakingNewsNotifications: true
        )
        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 300_000_000)
        let initialCount = sut.currentState.preferences.mutedKeywords.count
        sut.dispatch(action: .addMutedKeyword("existing"))
        try await Task.sleep(nanoseconds: 300_000_000)
        #expect(sut.currentState.preferences.mutedKeywords.count == initialCount)
    }

    @Test("Remove muted keyword removes from list")
    func removeMutedKeywordRemoves() async throws {
        let (sut, mock, _) = createSUT()
        mock.preferences = UserPreferences(
            followedTopics: [], followedSources: [], mutedSources: [], mutedKeywords: ["keyword1", "keyword2"],
            preferredLanguage: "en", notificationsEnabled: true, breakingNewsNotifications: true
        )
        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 300_000_000)
        sut.dispatch(action: .removeMutedKeyword("keyword1"))
        try await Task.sleep(nanoseconds: 300_000_000)
        #expect(!sut.currentState.preferences.mutedKeywords.contains("keyword1"))
        #expect(sut.currentState.preferences.mutedKeywords.contains("keyword2"))
    }

    @Test("Multiple muted sources can be added")
    func multipleMutedSourcesCanBeAdded() async throws {
        let (sut, mock, _) = createSUT()
        mock.preferences = .default
        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 300_000_000)
        sut.dispatch(action: .addMutedSource("Source 1"))
        try await Task.sleep(nanoseconds: 200_000_000)
        sut.dispatch(action: .addMutedSource("Source 2"))
        try await Task.sleep(nanoseconds: 200_000_000)
        let sources = sut.currentState.preferences.mutedSources
        #expect(sources.count == 2 && sources.contains("Source 1") && sources.contains("Source 2"))
    }
}

// MARK: - Saving Tests

@Suite("SettingsDomainInteractor Saving Tests")
@MainActor
struct SettingsInteractorSavingTests {
    @Test("Save operation sets saving state")
    func saveOperationSetsSavingState() async throws {
        let (sut, mock, _) = createSUT()
        mock.preferences = .default
        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 300_000_000)
        var cancellables = Set<AnyCancellable>()
        var savingStates: [Bool] = []
        sut.statePublisher.map(\.isSaving).sink { savingStates.append($0) }.store(in: &cancellables)
        sut.dispatch(action: .toggleNotifications(false))
        try await Task.sleep(nanoseconds: 300_000_000)
        #expect(savingStates.contains(true) && savingStates.last == false)
    }
}

// MARK: - UI State Action Tests

@Suite("SettingsDomainInteractor UI State Tests")
@MainActor
struct SettingsInteractorUIStateTests {
    @Test("Set show sign out confirmation")
    func setShowSignOutConfirmation() async throws {
        let (sut, _, _) = createSUT()

        sut.dispatch(action: .setShowSignOutConfirmation(true))
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(sut.currentState.showSignOutConfirmation)
    }

    @Test("Set show sign out confirmation back to false")
    func setShowSignOutConfirmationFalse() async throws {
        let (sut, _, _) = createSUT()

        sut.dispatch(action: .setShowSignOutConfirmation(true))
        try await Task.sleep(nanoseconds: 100_000_000)

        sut.dispatch(action: .setShowSignOutConfirmation(false))
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(!sut.currentState.showSignOutConfirmation)
    }

    @Test("Set new muted source text")
    func setNewMutedSource() async throws {
        let (sut, _, _) = createSUT()

        sut.dispatch(action: .setNewMutedSource("CNN"))
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(sut.currentState.newMutedSource == "CNN")
    }

    @Test("Set new muted keyword text")
    func setNewMutedKeyword() async throws {
        let (sut, _, _) = createSUT()

        sut.dispatch(action: .setNewMutedKeyword("politics"))
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(sut.currentState.newMutedKeyword == "politics")
    }

    @Test("Add muted source clears new muted source text")
    func addMutedSourceClearsText() async throws {
        let (sut, mock, _) = createSUT()
        mock.preferences = .default
        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 300_000_000)

        sut.dispatch(action: .setNewMutedSource("CNN"))
        try await Task.sleep(nanoseconds: 100_000_000)

        sut.dispatch(action: .addMutedSource("CNN"))
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.currentState.newMutedSource == "")
        #expect(sut.currentState.preferences.mutedSources.contains("CNN"))
    }

    @Test("Add empty muted source does not add")
    func addEmptyMutedSourceDoesNothing() async throws {
        let (sut, mock, _) = createSUT()
        mock.preferences = .default
        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 300_000_000)

        let initialCount = sut.currentState.preferences.mutedSources.count

        sut.dispatch(action: .addMutedSource(""))
        try await Task.sleep(nanoseconds: 200_000_000)

        #expect(sut.currentState.preferences.mutedSources.count == initialCount)
    }

    @Test("Add muted keyword clears new muted keyword text")
    func addMutedKeywordClearsText() async throws {
        let (sut, mock, _) = createSUT()
        mock.preferences = .default
        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 300_000_000)

        sut.dispatch(action: .setNewMutedKeyword("spam"))
        try await Task.sleep(nanoseconds: 100_000_000)

        sut.dispatch(action: .addMutedKeyword("spam"))
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.currentState.newMutedKeyword == "")
        #expect(sut.currentState.preferences.mutedKeywords.contains("spam"))
    }

    @Test("Add empty muted keyword does not add")
    func addEmptyMutedKeywordDoesNothing() async throws {
        let (sut, mock, _) = createSUT()
        mock.preferences = .default
        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 300_000_000)

        let initialCount = sut.currentState.preferences.mutedKeywords.count

        sut.dispatch(action: .addMutedKeyword(""))
        try await Task.sleep(nanoseconds: 200_000_000)

        #expect(sut.currentState.preferences.mutedKeywords.count == initialCount)
    }
}

// MARK: - State Publisher Tests

@Suite("SettingsDomainInteractor Publisher Tests")
@MainActor
struct SettingsInteractorPublisherTests {
    @Test("State publisher emits initial state")
    func statePublisherEmitsInitialState() async throws {
        let (sut, _, _) = createSUT()
        var cancellables = Set<AnyCancellable>()
        var states: [SettingsDomainState] = []

        sut.statePublisher
            .sink { state in states.append(state) }
            .store(in: &cancellables)

        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(!states.isEmpty)
        #expect(states[0].preferences == .default)
    }

    @Test("Notification posted on preferences change")
    func notificationPosted() async throws {
        let (sut, mock, _) = createSUT()
        mock.preferences = .default
        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 300_000_000)

        var notificationReceived = false
        let token = NotificationCenter.default.addObserver(
            forName: .userPreferencesDidChange,
            object: nil,
            queue: .main
        ) { _ in notificationReceived = true }

        sut.dispatch(action: .toggleNotifications(false))
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(notificationReceived)
        NotificationCenter.default.removeObserver(token)
    }
}

// MARK: - Analytics Tests

@Suite("SettingsDomainInteractor Analytics Tests")
@MainActor
struct SettingsInteractorAnalyticsTests {
    @Test("Logs screen_view on loadPreferences")
    func logsScreenViewOnLoad() async throws {
        let (sut, _, mockAnalytics) = createSUT()
        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 300_000_000)

        let screenEvents = mockAnalytics.loggedEvents.filter { $0.name == "screen_view" }
        #expect(screenEvents.count == 1)
        #expect(screenEvents.first?.parameters?["screen_name"] as? String == "settings")
    }
}
