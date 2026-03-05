import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("SettingsViewModel Extended Tests")
@MainActor
struct SettingsViewModelExtendedTests {
    let mockSettingsService: MockSettingsService
    let serviceLocator: ServiceLocator

    init() {
        mockSettingsService = MockSettingsService()
        serviceLocator = ServiceLocator()
        serviceLocator.register(SettingsService.self, instance: mockSettingsService)
    }

    private func createSUT() -> SettingsViewModel {
        SettingsViewModel(serviceLocator: serviceLocator)
    }

    // MARK: - Theme Events

    @Test("Toggle dark mode updates view state")
    func toggleDarkMode() async throws {
        let sut = createSUT()
        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 300_000_000)

        sut.handle(event: .onToggleDarkMode(true))
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.viewState.isDarkMode)
    }

    @Test("Toggle system theme updates view state")
    func toggleSystemTheme() async throws {
        let sut = createSUT()
        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 300_000_000)

        sut.handle(event: .onToggleSystemTheme(false))
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(!sut.viewState.useSystemTheme)
    }

    // MARK: - Sign Out Events

    @Test("Sign out tapped shows confirmation")
    func signOutTappedShowsConfirmation() async throws {
        let sut = createSUT()
        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 300_000_000)

        sut.handle(event: .onSignOutTapped)
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.viewState.showSignOutConfirmation)
    }

    @Test("Cancel sign out hides confirmation")
    func cancelSignOutHidesConfirmation() async throws {
        let sut = createSUT()
        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 300_000_000)

        sut.handle(event: .onSignOutTapped)
        try await Task.sleep(nanoseconds: 300_000_000)
        #expect(sut.viewState.showSignOutConfirmation)

        sut.handle(event: .onCancelSignOut)
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(!sut.viewState.showSignOutConfirmation)
    }

    // MARK: - Error Dismiss Events

    @Test("Dismiss error clears error message")
    func dismissErrorClearsMessage() async throws {
        let sut = createSUT()
        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 300_000_000)

        sut.handle(event: .onDismissError)
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.viewState.errorMessage == nil)
    }

    @Test("Dismiss notifications denied alert clears state")
    func dismissNotificationsDeniedAlert() async throws {
        let sut = createSUT()
        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 300_000_000)

        sut.handle(event: .onDismissNotificationsDeniedAlert)
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(!sut.viewState.showNotificationsDeniedAlert)
    }

    // MARK: - Language Change

    @Test("Language change updates selected language")
    func languageChange() async throws {
        let sut = createSUT()
        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 500_000_000)

        sut.handle(event: .onLanguageChanged("pt"))
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(sut.viewState.selectedLanguage == "pt")
    }

    // MARK: - Initial State Binding Tests

    @Test("Initial state has correct defaults from interactor binding")
    func initialStateDefaults() async throws {
        let sut = createSUT()
        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(!sut.viewState.showSignOutConfirmation)
        #expect(sut.viewState.errorMessage == nil)
        #expect(!sut.viewState.showNotificationsDeniedAlert)
        #expect(sut.viewState.newMutedSource.isEmpty)
        #expect(sut.viewState.newMutedKeyword.isEmpty)
    }

    // MARK: - Preferences Loading Tests

    @Test("Load preferences with followed topics")
    func loadPreferencesWithTopics() async throws {
        mockSettingsService.preferences = UserPreferences(
            followedTopics: [.technology, .science, .business],
            mutedSources: ["source1", "source2"],
            mutedKeywords: ["keyword1"],
            preferredLanguage: "es",
            notificationsEnabled: false,
            breakingNewsNotifications: false
        )

        let sut = createSUT()
        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(sut.viewState.mutedSources.count == 2)
        #expect(sut.viewState.mutedKeywords.count == 1)
        #expect(!sut.viewState.notificationsEnabled)
        #expect(!sut.viewState.breakingNewsEnabled)
        #expect(sut.viewState.selectedLanguage == "es")
    }

    // MARK: - Multiple Event Handling

    @Test("Multiple events handled in sequence")
    func multipleEventsInSequence() async throws {
        let sut = createSUT()
        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 500_000_000)

        sut.handle(event: .onNewMutedSourceChanged("Source1"))
        try await Task.sleep(nanoseconds: 100_000_000)
        sut.handle(event: .onAddMutedSource)
        try await Task.sleep(nanoseconds: 500_000_000)

        sut.handle(event: .onNewMutedKeywordChanged("Keyword1"))
        try await Task.sleep(nanoseconds: 100_000_000)
        sut.handle(event: .onAddMutedKeyword)
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(sut.viewState.mutedSources.contains("Source1"))
        #expect(sut.viewState.mutedKeywords.contains("Keyword1"))
    }
}
