import Testing
import Combine
@testable import Pulse

@Suite("SettingsViewModel Tests")
struct SettingsViewModelTests {
    var mockSettingsService: MockSettingsService!
    var sut: SettingsViewModel!
    var cancellables: Set<AnyCancellable>!

    init() {
        mockSettingsService = MockSettingsService()

        ServiceLocator.shared.register(SettingsService.self, service: mockSettingsService)

        sut = SettingsViewModel()
        cancellables = Set<AnyCancellable>()
    }

    @Test("Initial view state is correct")
    func testInitialViewState() {
        let state = sut.viewState
        #expect(state.followedTopics.isEmpty)
        #expect(state.allTopics == NewsCategory.allCases)
        #expect(state.mutedSources.isEmpty)
        #expect(state.mutedKeywords.isEmpty)
        #expect(!state.isLoading)
    }

    @Test("Load preferences updates state")
    func testLoadPreferences() async throws {
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
    func testToggleTopic() async throws {
        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 300_000_000)

        sut.handle(event: .onToggleTopic(.technology))
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.viewState.followedTopics.contains(.technology))
    }

    @Test("Toggle notifications updates state")
    func testToggleNotifications() async throws {
        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 300_000_000)

        sut.handle(event: .onToggleNotifications(false))
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(!sut.viewState.notificationsEnabled)
    }

    @Test("Add muted source works correctly")
    func testAddMutedSource() async throws {
        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 300_000_000)

        sut.newMutedSource = "TestSource"
        sut.handle(event: .onAddMutedSource)
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.viewState.mutedSources.contains("TestSource"))
        #expect(sut.newMutedSource.isEmpty)
    }

    @Test("Add muted keyword works correctly")
    func testAddMutedKeyword() async throws {
        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 300_000_000)

        sut.newMutedKeyword = "TestKeyword"
        sut.handle(event: .onAddMutedKeyword)
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.viewState.mutedKeywords.contains("TestKeyword"))
        #expect(sut.newMutedKeyword.isEmpty)
    }
}
