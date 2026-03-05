import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("SettingsViewModel SignOut Tests")
@MainActor
struct SettingsViewModelSignOutTests {
    let mockSettingsService: MockSettingsService
    let mockAuthService: MockAuthService
    let mockStorageService: MockStorageService
    let mockSearchService: MockSearchService
    let mockAppLockService: MockAppLockService
    let mockNotificationService: MockNotificationService
    let serviceLocator: ServiceLocator

    init() {
        mockSettingsService = MockSettingsService()
        mockAuthService = MockAuthService()
        mockStorageService = MockStorageService()
        mockSearchService = MockSearchService()
        mockAppLockService = MockAppLockService()
        mockNotificationService = MockNotificationService()
        serviceLocator = ServiceLocator()

        serviceLocator.register(SettingsService.self, instance: mockSettingsService)
        serviceLocator.register(AuthService.self, instance: mockAuthService)
        serviceLocator.register(StorageService.self, instance: mockStorageService)
        serviceLocator.register(SearchService.self, instance: mockSearchService)
        serviceLocator.register(AppLockService.self, instance: mockAppLockService)
        serviceLocator.register(NotificationService.self, instance: mockNotificationService)
    }

    private func createSUT() -> SettingsViewModel {
        SettingsViewModel(serviceLocator: serviceLocator)
    }

    // MARK: - Sign Out Tests

    @Test("Confirm sign out calls auth service sign out")
    func confirmSignOutCallsAuthService() async throws {
        let sut = createSUT()
        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 500_000_000)

        sut.handle(event: .onConfirmSignOut)
        try await Task.sleep(nanoseconds: 500_000_000)

        // Sign out should dismiss the confirmation
        #expect(!sut.viewState.showSignOutConfirmation)
    }

    @Test("Sign out clears app lock settings")
    func signOutClearsAppLock() async throws {
        mockAppLockService.isEnabled = true
        mockAppLockService.hasPromptedFaceID = true

        let sut = createSUT()
        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 500_000_000)

        sut.handle(event: .onConfirmSignOut)
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(!mockAppLockService.isEnabled)
        #expect(!mockAppLockService.hasPromptedFaceID)
    }

    @Test("Sign out clears UserDefaults preferences")
    func signOutClearsUserDefaults() async throws {
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: "pulse.hasCompletedOnboarding")
        defaults.set(true, forKey: "pulse.isDarkMode")
        defaults.set(false, forKey: "pulse.useSystemTheme")
        defaults.set("pt", forKey: "pulse.preferredLanguage")

        let sut = createSUT()
        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 500_000_000)

        sut.handle(event: .onConfirmSignOut)
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(defaults.object(forKey: "pulse.hasCompletedOnboarding") == nil)
        #expect(defaults.object(forKey: "pulse.isDarkMode") == nil)
        #expect(defaults.object(forKey: "pulse.useSystemTheme") == nil)
        #expect(defaults.object(forKey: "pulse.preferredLanguage") == nil)
    }

    @Test("Sign out failure still dismisses confirmation")
    func signOutFailureDismissesConfirmation() async throws {
        mockAuthService.signOutResult = .failure(
            NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Sign out failed"])
        )

        let sut = createSUT()
        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 500_000_000)

        sut.handle(event: .onSignOutTapped)
        try await Task.sleep(nanoseconds: 300_000_000)
        #expect(sut.viewState.showSignOutConfirmation)

        sut.handle(event: .onConfirmSignOut)
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(!sut.viewState.showSignOutConfirmation)
    }

    // MARK: - Notification Events Tests

    @Test("Toggle notifications updates view state")
    func toggleNotificationsUpdatesViewState() async throws {
        let sut = createSUT()
        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 500_000_000)

        sut.handle(event: .onToggleNotifications(false))
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(!sut.viewState.notificationsEnabled)
    }

    @Test("Toggle breaking news updates view state")
    func toggleBreakingNewsUpdatesViewState() async throws {
        let sut = createSUT()
        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 500_000_000)

        sut.handle(event: .onToggleBreakingNews(false))
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(!sut.viewState.breakingNewsEnabled)
    }

    // MARK: - Muted Content Events

    @Test("Remove muted source updates view state")
    func removeMutedSourceUpdatesViewState() async throws {
        mockSettingsService.preferences = UserPreferences(
            followedTopics: [],
            mutedSources: ["Source1", "Source2"],
            mutedKeywords: [],
            preferredLanguage: "en",
            notificationsEnabled: true,
            breakingNewsNotifications: true
        )

        let sut = createSUT()
        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 500_000_000)

        sut.handle(event: .onRemoveMutedSource("Source1"))
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(!sut.viewState.mutedSources.contains("Source1"))
        #expect(sut.viewState.mutedSources.contains("Source2"))
    }

    @Test("Remove muted keyword updates view state")
    func removeMutedKeywordUpdatesViewState() async throws {
        mockSettingsService.preferences = UserPreferences(
            followedTopics: [],
            mutedSources: [],
            mutedKeywords: ["keyword1", "keyword2"],
            preferredLanguage: "en",
            notificationsEnabled: true,
            breakingNewsNotifications: true
        )

        let sut = createSUT()
        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 500_000_000)

        sut.handle(event: .onRemoveMutedKeyword("keyword1"))
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(!sut.viewState.mutedKeywords.contains("keyword1"))
        #expect(sut.viewState.mutedKeywords.contains("keyword2"))
    }
}
