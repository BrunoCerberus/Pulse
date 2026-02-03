import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

// MARK: - Test Helpers

@MainActor
private func createSUT() -> (SettingsDomainInteractor, MockSettingsService) {
    let mockSettingsService = MockSettingsService()
    let serviceLocator = ServiceLocator()
    serviceLocator.register(SettingsService.self, instance: mockSettingsService)
    return (SettingsDomainInteractor(serviceLocator: serviceLocator), mockSettingsService)
}

// MARK: - Initial State & Load Tests

@Suite("SettingsDomainInteractor State Tests")
@MainActor
struct SettingsInteractorStateTests {
    @Test("Initial state is correct")
    func initialState() {
        let (sut, _) = createSUT()
        let state = sut.currentState
        #expect(state.preferences == .default)
        #expect(!state.isLoading)
        #expect(!state.isSaving)
        #expect(state.error == nil)
    }

    @Test("Load preferences populates state")
    func loadPreferencesPopulatesState() async throws {
        let (sut, mock) = createSUT()
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
        let (sut, _) = createSUT()
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
        let (sut, mock) = createSUT()
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
        let (sut, mock) = createSUT()
        mock.preferences = .default
        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 300_000_000)
        sut.dispatch(action: .toggleNotifications(false))
        try await Task.sleep(nanoseconds: 300_000_000)
        #expect(!sut.currentState.preferences.notificationsEnabled)
    }

    @Test("Toggle breaking news enables when disabled")
    func toggleBreakingNewsEnables() async throws {
        let (sut, mock) = createSUT()
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
        let (sut, mock) = createSUT()
        mock.preferences = .default
        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 300_000_000)
        sut.dispatch(action: .toggleBreakingNews(false))
        try await Task.sleep(nanoseconds: 300_000_000)
        #expect(!sut.currentState.preferences.breakingNewsNotifications)
    }
}

// MARK: - Muted Content Tests

@Suite("SettingsDomainInteractor Muted Tests")
@MainActor
struct SettingsInteractorMutedTests {
    @Test("Add muted source appends to list")
    func addMutedSourceAppends() async throws {
        let (sut, mock) = createSUT()
        mock.preferences = .default
        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 300_000_000)
        sut.dispatch(action: .addMutedSource("Spam News"))
        try await Task.sleep(nanoseconds: 300_000_000)
        #expect(sut.currentState.preferences.mutedSources.contains("Spam News"))
    }

    @Test("Add muted source prevents duplicates")
    func addMutedSourcePreventsDuplicates() async throws {
        let (sut, mock) = createSUT()
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
        let (sut, mock) = createSUT()
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
        let (sut, mock) = createSUT()
        mock.preferences = .default
        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 300_000_000)
        sut.dispatch(action: .addMutedKeyword("clickbait"))
        try await Task.sleep(nanoseconds: 300_000_000)
        #expect(sut.currentState.preferences.mutedKeywords.contains("clickbait"))
    }

    @Test("Add muted keyword prevents duplicates")
    func addMutedKeywordPreventsDuplicates() async throws {
        let (sut, mock) = createSUT()
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
        let (sut, mock) = createSUT()
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
        let (sut, mock) = createSUT()
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
        let (sut, mock) = createSUT()
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
