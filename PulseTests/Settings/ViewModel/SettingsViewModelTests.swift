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
}
