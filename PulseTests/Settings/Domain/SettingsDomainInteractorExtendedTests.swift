import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

// MARK: - Notification Edge Cases

@Suite("SettingsDomainInteractor Notification Edge Cases")
@MainActor
struct SettingsNotificationEdgeTests {
    let mockSettingsService: MockSettingsService
    let mockNotificationService: MockNotificationService
    let serviceLocator: ServiceLocator

    init() {
        mockSettingsService = MockSettingsService()
        mockNotificationService = MockNotificationService()
        serviceLocator = ServiceLocator()

        serviceLocator.register(SettingsService.self, instance: mockSettingsService)
        serviceLocator.register(AnalyticsService.self, instance: MockAnalyticsService())
        serviceLocator.register(NotificationService.self, instance: mockNotificationService)
    }

    private func createSUT(
        notificationStatus: NotificationAuthorizationStatus = .authorized
    ) -> SettingsDomainInteractor {
        mockNotificationService.authorizationStatusResult = notificationStatus
        return SettingsDomainInteractor(serviceLocator: serviceLocator)
    }

    @Test("Toggle notifications denied shows alert")
    func toggleNotificationsDeniedShowsAlert() async throws {
        let sut = createSUT(notificationStatus: .denied)
        mockSettingsService.preferences = .default
        sut.dispatch(action: .loadPreferences)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        sut.dispatch(action: .toggleNotifications(true))
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(sut.currentState.showNotificationsDeniedAlert)
        #expect(!sut.currentState.preferences.notificationsEnabled)
    }

    @Test("Toggle notifications not determined requests authorization")
    func toggleNotificationsNotDeterminedRequestsAuth() async throws {
        let sut = createSUT(notificationStatus: .notDetermined)
        mockNotificationService.requestAuthorizationResult = .success(true)
        mockSettingsService.preferences = .default
        sut.dispatch(action: .loadPreferences)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        sut.dispatch(action: .toggleNotifications(true))
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(mockNotificationService.requestAuthorizationCallCount == 1)
        #expect(sut.currentState.preferences.notificationsEnabled)
    }

    @Test("Toggle notifications not determined denied by user")
    func toggleNotificationsNotDeterminedDenied() async throws {
        let sut = createSUT(notificationStatus: .notDetermined)
        mockNotificationService.requestAuthorizationResult = .success(false)
        mockSettingsService.preferences = .default
        sut.dispatch(action: .loadPreferences)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        sut.dispatch(action: .toggleNotifications(true))
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(!sut.currentState.preferences.notificationsEnabled)
    }

    @Test("Toggle notifications not determined authorization error")
    func toggleNotificationsAuthError() async throws {
        let sut = createSUT(notificationStatus: .notDetermined)
        mockNotificationService.requestAuthorizationResult = .failure(
            NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Auth failed"])
        )
        mockSettingsService.preferences = .default
        sut.dispatch(action: .loadPreferences)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        sut.dispatch(action: .toggleNotifications(true))
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(!sut.currentState.preferences.notificationsEnabled)
        #expect(sut.currentState.error != nil)
    }

    @Test("Toggle notifications authorized registers for remote")
    func toggleNotificationsAuthorizedRegisters() async throws {
        let sut = createSUT(notificationStatus: .authorized)
        mockSettingsService.preferences = .default
        sut.dispatch(action: .loadPreferences)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        sut.dispatch(action: .toggleNotifications(true))
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(mockNotificationService.registerCallCount >= 1)
        #expect(sut.currentState.preferences.notificationsEnabled)
    }

    @Test("Toggle notifications provisional registers for remote")
    func toggleNotificationsProvisionalRegisters() async throws {
        let sut = createSUT(notificationStatus: .provisional)
        mockSettingsService.preferences = .default
        sut.dispatch(action: .loadPreferences)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        sut.dispatch(action: .toggleNotifications(true))
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(mockNotificationService.registerCallCount >= 1)
        #expect(sut.currentState.preferences.notificationsEnabled)
    }

    @Test("Toggle notifications off unregisters for remote")
    func toggleNotificationsOffUnregisters() async throws {
        let sut = createSUT()
        mockSettingsService.preferences = UserPreferences(
            followedTopics: [], mutedSources: [], mutedKeywords: [],
            preferredLanguage: "en", notificationsEnabled: true, breakingNewsNotifications: true
        )
        sut.dispatch(action: .loadPreferences)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        sut.dispatch(action: .toggleNotifications(false))
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(mockNotificationService.unregisterCallCount >= 1)
        #expect(!sut.currentState.preferences.notificationsEnabled)
    }

    // MARK: - Sync Notification Status

    @Test("Sync notification status disables when OS denied")
    func syncNotificationStatusDisablesWhenDenied() async throws {
        let sut = createSUT(notificationStatus: .denied)
        mockSettingsService.preferences = UserPreferences(
            followedTopics: [], mutedSources: [], mutedKeywords: [],
            preferredLanguage: "en", notificationsEnabled: true, breakingNewsNotifications: true
        )
        sut.dispatch(action: .loadPreferences)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        // syncNotificationStatus is called automatically after loadPreferences
        #expect(!sut.currentState.preferences.notificationsEnabled)
    }

    @Test("Sync notification status keeps enabled when OS authorized")
    func syncNotificationStatusKeepsWhenAuthorized() async throws {
        let sut = createSUT(notificationStatus: .authorized)
        mockSettingsService.preferences = UserPreferences(
            followedTopics: [], mutedSources: [], mutedKeywords: [],
            preferredLanguage: "en", notificationsEnabled: true, breakingNewsNotifications: true
        )
        sut.dispatch(action: .loadPreferences)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(sut.currentState.preferences.notificationsEnabled)
    }

    // MARK: - Dismiss Actions

    @Test("Dismiss error clears error state")
    func dismissErrorClearsError() async throws {
        let sut = createSUT()

        sut.dispatch(action: .dismissError)
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        #expect(sut.currentState.error == nil)
    }

    @Test("Dismiss notifications denied alert clears state")
    func dismissNotificationsDeniedAlert() async throws {
        let sut = createSUT(notificationStatus: .denied)
        mockSettingsService.preferences = .default
        sut.dispatch(action: .loadPreferences)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        sut.dispatch(action: .toggleNotifications(true))
        try await waitForStateUpdate(duration: TestWaitDuration.long)
        #expect(sut.currentState.showNotificationsDeniedAlert)

        sut.dispatch(action: .dismissNotificationsDeniedAlert)
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        #expect(!sut.currentState.showNotificationsDeniedAlert)
    }
}
