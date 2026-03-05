import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

// MARK: - Notification Edge Cases

@Suite("SettingsDomainInteractor Notification Edge Cases")
@MainActor
struct SettingsNotificationEdgeTests {
    // swiftlint:disable large_tuple
    @MainActor
    private func createSUT(
        notificationStatus: NotificationAuthorizationStatus = .authorized
    ) -> (SettingsDomainInteractor, MockSettingsService, MockAnalyticsService, MockNotificationService) {
        // swiftlint:enable large_tuple
        let mockSettingsService = MockSettingsService()
        let mockAnalyticsService = MockAnalyticsService()
        let mockNotificationService = MockNotificationService()
        mockNotificationService.authorizationStatusResult = notificationStatus
        let serviceLocator = ServiceLocator()
        serviceLocator.register(SettingsService.self, instance: mockSettingsService)
        serviceLocator.register(AnalyticsService.self, instance: mockAnalyticsService)
        serviceLocator.register(NotificationService.self, instance: mockNotificationService)
        return (
            SettingsDomainInteractor(serviceLocator: serviceLocator),
            mockSettingsService, mockAnalyticsService, mockNotificationService
        )
    }

    @Test("Toggle notifications denied shows alert")
    func toggleNotificationsDeniedShowsAlert() async throws {
        let (sut, mock, _, _) = createSUT(notificationStatus: .denied)
        mock.preferences = .default
        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 300_000_000)

        sut.dispatch(action: .toggleNotifications(true))
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.currentState.showNotificationsDeniedAlert)
        #expect(!sut.currentState.preferences.notificationsEnabled)
    }

    @Test("Toggle notifications not determined requests authorization")
    func toggleNotificationsNotDeterminedRequestsAuth() async throws {
        let (sut, mock, _, mockNotification) = createSUT(notificationStatus: .notDetermined)
        mockNotification.requestAuthorizationResult = .success(true)
        mock.preferences = .default
        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 300_000_000)

        sut.dispatch(action: .toggleNotifications(true))
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(mockNotification.requestAuthorizationCallCount == 1)
        #expect(sut.currentState.preferences.notificationsEnabled)
    }

    @Test("Toggle notifications not determined denied by user")
    func toggleNotificationsNotDeterminedDenied() async throws {
        let (sut, mock, _, mockNotification) = createSUT(notificationStatus: .notDetermined)
        mockNotification.requestAuthorizationResult = .success(false)
        mock.preferences = .default
        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 300_000_000)

        sut.dispatch(action: .toggleNotifications(true))
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(!sut.currentState.preferences.notificationsEnabled)
    }

    @Test("Toggle notifications not determined authorization error")
    func toggleNotificationsAuthError() async throws {
        let (sut, mock, _, mockNotification) = createSUT(notificationStatus: .notDetermined)
        mockNotification.requestAuthorizationResult = .failure(
            NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Auth failed"])
        )
        mock.preferences = .default
        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 300_000_000)

        sut.dispatch(action: .toggleNotifications(true))
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(!sut.currentState.preferences.notificationsEnabled)
        #expect(sut.currentState.error != nil)
    }

    @Test("Toggle notifications authorized registers for remote")
    func toggleNotificationsAuthorizedRegisters() async throws {
        let (sut, mock, _, mockNotification) = createSUT(notificationStatus: .authorized)
        mock.preferences = .default
        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 300_000_000)

        sut.dispatch(action: .toggleNotifications(true))
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(mockNotification.registerCallCount >= 1)
        #expect(sut.currentState.preferences.notificationsEnabled)
    }

    @Test("Toggle notifications provisional registers for remote")
    func toggleNotificationsProvisionalRegisters() async throws {
        let (sut, mock, _, mockNotification) = createSUT(notificationStatus: .provisional)
        mock.preferences = .default
        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 300_000_000)

        sut.dispatch(action: .toggleNotifications(true))
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(mockNotification.registerCallCount >= 1)
        #expect(sut.currentState.preferences.notificationsEnabled)
    }

    @Test("Toggle notifications off unregisters for remote")
    func toggleNotificationsOffUnregisters() async throws {
        let (sut, mock, _, mockNotification) = createSUT()
        mock.preferences = UserPreferences(
            followedTopics: [], mutedSources: [], mutedKeywords: [],
            preferredLanguage: "en", notificationsEnabled: true, breakingNewsNotifications: true
        )
        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 300_000_000)

        sut.dispatch(action: .toggleNotifications(false))
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(mockNotification.unregisterCallCount >= 1)
        #expect(!sut.currentState.preferences.notificationsEnabled)
    }

    // MARK: - Sync Notification Status

    @Test("Sync notification status disables when OS denied")
    func syncNotificationStatusDisablesWhenDenied() async throws {
        let (sut, mock, _, _) = createSUT(notificationStatus: .denied)
        mock.preferences = UserPreferences(
            followedTopics: [], mutedSources: [], mutedKeywords: [],
            preferredLanguage: "en", notificationsEnabled: true, breakingNewsNotifications: true
        )
        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 500_000_000)

        // syncNotificationStatus is called automatically after loadPreferences
        #expect(!sut.currentState.preferences.notificationsEnabled)
    }

    @Test("Sync notification status keeps enabled when OS authorized")
    func syncNotificationStatusKeepsWhenAuthorized() async throws {
        let (sut, mock, _, _) = createSUT(notificationStatus: .authorized)
        mock.preferences = UserPreferences(
            followedTopics: [], mutedSources: [], mutedKeywords: [],
            preferredLanguage: "en", notificationsEnabled: true, breakingNewsNotifications: true
        )
        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(sut.currentState.preferences.notificationsEnabled)
    }

    // MARK: - Dismiss Actions

    @Test("Dismiss error clears error state")
    func dismissErrorClearsError() async throws {
        let (sut, _, _, _) = createSUT()

        sut.dispatch(action: .dismissError)
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(sut.currentState.error == nil)
    }

    @Test("Dismiss notifications denied alert clears state")
    func dismissNotificationsDeniedAlert() async throws {
        let (sut, mock, _, _) = createSUT(notificationStatus: .denied)
        mock.preferences = .default
        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 300_000_000)

        sut.dispatch(action: .toggleNotifications(true))
        try await Task.sleep(nanoseconds: 300_000_000)
        #expect(sut.currentState.showNotificationsDeniedAlert)

        sut.dispatch(action: .dismissNotificationsDeniedAlert)
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(!sut.currentState.showNotificationsDeniedAlert)
    }
}
