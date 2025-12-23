import Combine
import Foundation
@testable import Pulse
import Testing

@Suite("SettingsDomainInteractor Tests")
@MainActor
struct SettingsDomainInteractorTests {
    let mockSettingsService: MockSettingsService
    let serviceLocator: ServiceLocator
    let sut: SettingsDomainInteractor

    init() {
        mockSettingsService = MockSettingsService()
        serviceLocator = ServiceLocator()

        serviceLocator.register(SettingsService.self, instance: mockSettingsService)

        sut = SettingsDomainInteractor(serviceLocator: serviceLocator)
    }

    // MARK: - Initial State Tests

    @Test("Initial state is correct")
    func initialState() {
        let state = sut.currentState
        #expect(state.preferences == .default)
        #expect(!state.isLoading)
        #expect(!state.isSaving)
        #expect(state.error == nil)
        #expect(!state.showClearHistoryConfirmation)
    }

    // MARK: - Load Preferences Tests

    @Test("Load preferences populates state")
    func loadPreferencesPopulatesState() async throws {
        let customPreferences = UserPreferences(
            followedTopics: [.technology, .science],
            followedSources: ["TechCrunch"],
            mutedSources: ["Spam Source"],
            mutedKeywords: ["clickbait"],
            preferredLanguage: "en",
            notificationsEnabled: true,
            breakingNewsNotifications: false
        )
        mockSettingsService.preferences = customPreferences

        sut.dispatch(action: .loadPreferences)

        try await Task.sleep(nanoseconds: 300_000_000)

        let state = sut.currentState
        #expect(!state.isLoading)
        #expect(state.preferences == customPreferences)
        #expect(state.error == nil)
    }

    @Test("Load preferences sets loading state")
    func loadPreferencesSetsLoadingState() async throws {
        var cancellables = Set<AnyCancellable>()
        var loadingStates: [Bool] = []

        sut.statePublisher
            .map(\.isLoading)
            .sink { isLoading in
                loadingStates.append(isLoading)
            }
            .store(in: &cancellables)

        sut.dispatch(action: .loadPreferences)

        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(loadingStates.contains(true))
        #expect(loadingStates.last == false)
    }

    // MARK: - Toggle Topic Tests

    @Test("Toggle topic adds topic when not followed")
    func toggleTopicAddsWhenNotFollowed() async throws {
        mockSettingsService.preferences = .default

        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(!sut.currentState.preferences.followedTopics.contains(.technology))

        sut.dispatch(action: .toggleTopic(.technology))

        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.currentState.preferences.followedTopics.contains(.technology))
    }

    @Test("Toggle topic removes topic when already followed")
    func toggleTopicRemovesWhenFollowed() async throws {
        mockSettingsService.preferences = UserPreferences(
            followedTopics: [.technology, .science],
            followedSources: [],
            mutedSources: [],
            mutedKeywords: [],
            preferredLanguage: "en",
            notificationsEnabled: true,
            breakingNewsNotifications: true
        )

        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.currentState.preferences.followedTopics.contains(.technology))

        sut.dispatch(action: .toggleTopic(.technology))

        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(!sut.currentState.preferences.followedTopics.contains(.technology))
    }

    @Test("Toggle topic saves preferences")
    func toggleTopicSavesPreferences() async throws {
        mockSettingsService.preferences = .default

        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 300_000_000)

        sut.dispatch(action: .toggleTopic(.sports))

        try await Task.sleep(nanoseconds: 300_000_000)

        // Verify service was updated
        #expect(mockSettingsService.preferences.followedTopics.contains(.sports))
    }

    // MARK: - Toggle Notifications Tests

    @Test("Toggle notifications enables when disabled")
    func toggleNotificationsEnables() async throws {
        mockSettingsService.preferences = UserPreferences(
            followedTopics: [],
            followedSources: [],
            mutedSources: [],
            mutedKeywords: [],
            preferredLanguage: "en",
            notificationsEnabled: false,
            breakingNewsNotifications: true
        )

        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 300_000_000)

        sut.dispatch(action: .toggleNotifications(true))

        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.currentState.preferences.notificationsEnabled)
    }

    @Test("Toggle notifications disables when enabled")
    func toggleNotificationsDisables() async throws {
        mockSettingsService.preferences = .default // notificationsEnabled is true by default

        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 300_000_000)

        sut.dispatch(action: .toggleNotifications(false))

        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(!sut.currentState.preferences.notificationsEnabled)
    }

    // MARK: - Toggle Breaking News Tests

    @Test("Toggle breaking news enables when disabled")
    func toggleBreakingNewsEnables() async throws {
        mockSettingsService.preferences = UserPreferences(
            followedTopics: [],
            followedSources: [],
            mutedSources: [],
            mutedKeywords: [],
            preferredLanguage: "en",
            notificationsEnabled: true,
            breakingNewsNotifications: false
        )

        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 300_000_000)

        sut.dispatch(action: .toggleBreakingNews(true))

        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.currentState.preferences.breakingNewsNotifications)
    }

    @Test("Toggle breaking news disables when enabled")
    func toggleBreakingNewsDisables() async throws {
        mockSettingsService.preferences = .default // breakingNewsNotifications is true by default

        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 300_000_000)

        sut.dispatch(action: .toggleBreakingNews(false))

        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(!sut.currentState.preferences.breakingNewsNotifications)
    }

    // MARK: - Muted Sources Tests

    @Test("Add muted source appends to list")
    func addMutedSourceAppends() async throws {
        mockSettingsService.preferences = .default

        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.currentState.preferences.mutedSources.isEmpty)

        sut.dispatch(action: .addMutedSource("Spam News"))

        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.currentState.preferences.mutedSources.contains("Spam News"))
    }

    @Test("Add muted source prevents duplicates")
    func addMutedSourcePreventsDuplicates() async throws {
        mockSettingsService.preferences = UserPreferences(
            followedTopics: [],
            followedSources: [],
            mutedSources: ["Existing Source"],
            mutedKeywords: [],
            preferredLanguage: "en",
            notificationsEnabled: true,
            breakingNewsNotifications: true
        )

        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 300_000_000)

        let initialCount = sut.currentState.preferences.mutedSources.count

        sut.dispatch(action: .addMutedSource("Existing Source"))

        try await Task.sleep(nanoseconds: 300_000_000)

        // Count should remain the same
        #expect(sut.currentState.preferences.mutedSources.count == initialCount)
    }

    @Test("Remove muted source removes from list")
    func removeMutedSourceRemoves() async throws {
        mockSettingsService.preferences = UserPreferences(
            followedTopics: [],
            followedSources: [],
            mutedSources: ["Source 1", "Source 2"],
            mutedKeywords: [],
            preferredLanguage: "en",
            notificationsEnabled: true,
            breakingNewsNotifications: true
        )

        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 300_000_000)

        sut.dispatch(action: .removeMutedSource("Source 1"))

        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(!sut.currentState.preferences.mutedSources.contains("Source 1"))
        #expect(sut.currentState.preferences.mutedSources.contains("Source 2"))
    }

    // MARK: - Muted Keywords Tests

    @Test("Add muted keyword appends to list")
    func addMutedKeywordAppends() async throws {
        mockSettingsService.preferences = .default

        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.currentState.preferences.mutedKeywords.isEmpty)

        sut.dispatch(action: .addMutedKeyword("clickbait"))

        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.currentState.preferences.mutedKeywords.contains("clickbait"))
    }

    @Test("Add muted keyword prevents duplicates")
    func addMutedKeywordPreventsDuplicates() async throws {
        mockSettingsService.preferences = UserPreferences(
            followedTopics: [],
            followedSources: [],
            mutedSources: [],
            mutedKeywords: ["existing"],
            preferredLanguage: "en",
            notificationsEnabled: true,
            breakingNewsNotifications: true
        )

        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 300_000_000)

        let initialCount = sut.currentState.preferences.mutedKeywords.count

        sut.dispatch(action: .addMutedKeyword("existing"))

        try await Task.sleep(nanoseconds: 300_000_000)

        // Count should remain the same
        #expect(sut.currentState.preferences.mutedKeywords.count == initialCount)
    }

    @Test("Remove muted keyword removes from list")
    func removeMutedKeywordRemoves() async throws {
        mockSettingsService.preferences = UserPreferences(
            followedTopics: [],
            followedSources: [],
            mutedSources: [],
            mutedKeywords: ["keyword1", "keyword2"],
            preferredLanguage: "en",
            notificationsEnabled: true,
            breakingNewsNotifications: true
        )

        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 300_000_000)

        sut.dispatch(action: .removeMutedKeyword("keyword1"))

        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(!sut.currentState.preferences.mutedKeywords.contains("keyword1"))
        #expect(sut.currentState.preferences.mutedKeywords.contains("keyword2"))
    }

    // MARK: - Clear Reading History Tests

    @Test("Clear reading history calls service")
    func clearReadingHistoryCallsService() async throws {
        sut.dispatch(action: .setShowClearHistoryConfirmation(true))
        #expect(sut.currentState.showClearHistoryConfirmation)

        sut.dispatch(action: .clearReadingHistory)

        try await Task.sleep(nanoseconds: 300_000_000)

        // Confirmation should be dismissed
        #expect(!sut.currentState.showClearHistoryConfirmation)
    }

    // MARK: - Show Clear History Confirmation Tests

    @Test("Set show clear history confirmation shows dialog")
    func setShowClearHistoryConfirmationShows() {
        sut.dispatch(action: .setShowClearHistoryConfirmation(true))

        #expect(sut.currentState.showClearHistoryConfirmation)
    }

    @Test("Set show clear history confirmation hides dialog")
    func setShowClearHistoryConfirmationHides() {
        sut.dispatch(action: .setShowClearHistoryConfirmation(true))
        #expect(sut.currentState.showClearHistoryConfirmation)

        sut.dispatch(action: .setShowClearHistoryConfirmation(false))
        #expect(!sut.currentState.showClearHistoryConfirmation)
    }

    // MARK: - Save State Tests

    @Test("Save operation sets saving state")
    func saveOperationSetsSavingState() async throws {
        mockSettingsService.preferences = .default

        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 300_000_000)

        var cancellables = Set<AnyCancellable>()
        var savingStates: [Bool] = []

        sut.statePublisher
            .map(\.isSaving)
            .sink { isSaving in
                savingStates.append(isSaving)
            }
            .store(in: &cancellables)

        sut.dispatch(action: .toggleTopic(.business))

        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(savingStates.contains(true))
        #expect(savingStates.last == false)
    }

    // MARK: - Multiple Operations Tests

    @Test("Multiple topics can be toggled")
    func multipleTopicsCanBeToggled() async throws {
        mockSettingsService.preferences = .default

        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 300_000_000)

        sut.dispatch(action: .toggleTopic(.technology))
        try await Task.sleep(nanoseconds: 200_000_000)

        sut.dispatch(action: .toggleTopic(.science))
        try await Task.sleep(nanoseconds: 200_000_000)

        sut.dispatch(action: .toggleTopic(.health))
        try await Task.sleep(nanoseconds: 200_000_000)

        let topics = sut.currentState.preferences.followedTopics
        #expect(topics.contains(.technology))
        #expect(topics.contains(.science))
        #expect(topics.contains(.health))
    }

    @Test("Multiple muted sources can be added")
    func multipleMutedSourcesCanBeAdded() async throws {
        mockSettingsService.preferences = .default

        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 300_000_000)

        sut.dispatch(action: .addMutedSource("Source 1"))
        try await Task.sleep(nanoseconds: 200_000_000)

        sut.dispatch(action: .addMutedSource("Source 2"))
        try await Task.sleep(nanoseconds: 200_000_000)

        let sources = sut.currentState.preferences.mutedSources
        #expect(sources.count == 2)
        #expect(sources.contains("Source 1"))
        #expect(sources.contains("Source 2"))
    }
}
