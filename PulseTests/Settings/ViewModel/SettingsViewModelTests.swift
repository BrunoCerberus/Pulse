import Combine
import Foundation
@testable import Pulse
import Testing

@Suite("SettingsViewModel Tests")
@MainActor
struct SettingsViewModelTests {
    let mockSettingsService: MockSettingsService
    let serviceLocator: ServiceLocator
    let sut: SettingsViewModel

    init() {
        mockSettingsService = MockSettingsService()
        serviceLocator = ServiceLocator()

        serviceLocator.register(SettingsService.self, instance: mockSettingsService)

        sut = SettingsViewModel(serviceLocator: serviceLocator)
    }

    @Test("Initial view state is correct")
    func initialViewState() {
        let state = sut.viewState
        #expect(state.followedTopics.isEmpty)
        #expect(state.allTopics == NewsCategory.allCases)
        #expect(state.mutedSources.isEmpty)
        #expect(state.mutedKeywords.isEmpty)
        #expect(!state.isLoading)
    }

    @Test("Load preferences updates state")
    func loadPreferences() async throws {
        mockSettingsService.preferences = UserPreferences(
            followedTopics: [.technology, .science],
            followedSources: [],
            mutedSources: ["source1"],
            mutedKeywords: ["keyword1"],
            preferredLanguage: "en",
            notificationsEnabled: true,
            breakingNewsNotifications: false
        )

        sut.handle(event: .onAppear)

        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(sut.viewState.followedTopics.contains(.technology))
        #expect(sut.viewState.mutedSources.contains("source1"))
    }

    @Test("Toggle topic adds/removes topic")
    func toggleTopic() async throws {
        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 300_000_000)

        sut.handle(event: .onToggleTopic(.technology))
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.viewState.followedTopics.contains(.technology))
    }

    @Test("Toggle notifications updates state")
    func toggleNotifications() async throws {
        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 300_000_000)

        sut.handle(event: .onToggleNotifications(false))
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(!sut.viewState.notificationsEnabled)
    }

    @Test("Add muted source works correctly")
    func addMutedSource() async throws {
        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 300_000_000)

        sut.newMutedSource = "TestSource"
        sut.handle(event: .onAddMutedSource)
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.viewState.mutedSources.contains("TestSource"))
        #expect(sut.newMutedSource.isEmpty)
    }

    @Test("Add muted keyword works correctly")
    func addMutedKeyword() async throws {
        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 300_000_000)

        sut.newMutedKeyword = "TestKeyword"
        sut.handle(event: .onAddMutedKeyword)
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.viewState.mutedKeywords.contains("TestKeyword"))
        #expect(sut.newMutedKeyword.isEmpty)
    }

    // MARK: - Remove Tests

    @Test("Remove muted source works correctly")
    func removeMutedSource() async throws {
        mockSettingsService.preferences = UserPreferences(
            followedTopics: [],
            followedSources: [],
            mutedSources: ["source1", "source2"],
            mutedKeywords: [],
            preferredLanguage: "en",
            notificationsEnabled: true,
            breakingNewsNotifications: true
        )

        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 300_000_000)

        sut.handle(event: .onRemoveMutedSource("source1"))
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(!sut.viewState.mutedSources.contains("source1"))
        #expect(sut.viewState.mutedSources.contains("source2"))
    }

    @Test("Remove muted keyword works correctly")
    func removeMutedKeyword() async throws {
        mockSettingsService.preferences = UserPreferences(
            followedTopics: [],
            followedSources: [],
            mutedSources: [],
            mutedKeywords: ["keyword1", "keyword2"],
            preferredLanguage: "en",
            notificationsEnabled: true,
            breakingNewsNotifications: true
        )

        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 300_000_000)

        sut.handle(event: .onRemoveMutedKeyword("keyword1"))
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(!sut.viewState.mutedKeywords.contains("keyword1"))
        #expect(sut.viewState.mutedKeywords.contains("keyword2"))
    }

    // MARK: - Input Validation Tests

    @Test("Empty muted source is not added")
    func emptyMutedSourceNotAdded() async throws {
        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 300_000_000)

        sut.newMutedSource = ""
        sut.handle(event: .onAddMutedSource)
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.viewState.mutedSources.isEmpty)
    }

    @Test("Empty muted keyword is not added")
    func emptyMutedKeywordNotAdded() async throws {
        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 300_000_000)

        sut.newMutedKeyword = ""
        sut.handle(event: .onAddMutedKeyword)
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.viewState.mutedKeywords.isEmpty)
    }

    // MARK: - Toggle Breaking News Tests

    @Test("Toggle breaking news updates state")
    func toggleBreakingNews() async throws {
        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 300_000_000)

        sut.handle(event: .onToggleBreakingNews(false))
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(!sut.viewState.breakingNewsEnabled)
    }

    // MARK: - Clear History Tests

    @Test("Clear history shows confirmation")
    func clearHistoryShowsConfirmation() async throws {
        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 300_000_000)

        sut.handle(event: .onClearReadingHistory)
        try await Task.sleep(nanoseconds: 200_000_000)

        #expect(sut.viewState.showClearHistoryConfirmation)
    }

    @Test("Cancel clear history hides confirmation")
    func cancelClearHistoryHidesConfirmation() async throws {
        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 300_000_000)

        sut.handle(event: .onClearReadingHistory)
        try await Task.sleep(nanoseconds: 200_000_000)

        #expect(sut.viewState.showClearHistoryConfirmation)

        sut.handle(event: .onCancelClearHistory)
        try await Task.sleep(nanoseconds: 200_000_000)

        #expect(!sut.viewState.showClearHistoryConfirmation)
    }

    @Test("Confirm clear history clears and hides confirmation")
    func confirmClearHistoryClearsAndHides() async throws {
        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 300_000_000)

        sut.handle(event: .onClearReadingHistory)
        try await Task.sleep(nanoseconds: 200_000_000)

        sut.handle(event: .onConfirmClearHistory)
        try await Task.sleep(nanoseconds: 200_000_000)

        #expect(!sut.viewState.showClearHistoryConfirmation)
    }

    // MARK: - Topic Toggle Tests

    @Test("Toggle topic removes when already followed")
    func toggleTopicRemovesWhenFollowed() async throws {
        mockSettingsService.preferences = UserPreferences(
            followedTopics: [.technology],
            followedSources: [],
            mutedSources: [],
            mutedKeywords: [],
            preferredLanguage: "en",
            notificationsEnabled: true,
            breakingNewsNotifications: true
        )

        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.viewState.followedTopics.contains(.technology))

        sut.handle(event: .onToggleTopic(.technology))
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(!sut.viewState.followedTopics.contains(.technology))
    }

    // MARK: - View State Binding Tests

    @Test("View state updates through publisher binding")
    func viewStateUpdatesThroughPublisher() async throws {
        var cancellables = Set<AnyCancellable>()
        var states: [SettingsViewState] = []

        sut.$viewState
            .sink { state in
                states.append(state)
            }
            .store(in: &cancellables)

        sut.handle(event: .onAppear)

        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(states.count > 1)
    }

    @Test("All topics are available in state")
    func allTopicsAvailableInState() {
        #expect(sut.viewState.allTopics == NewsCategory.allCases)
        #expect(sut.viewState.allTopics.count == 7)
    }
}
