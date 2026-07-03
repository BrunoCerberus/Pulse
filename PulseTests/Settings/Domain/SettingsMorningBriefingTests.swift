import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

// MARK: - Test Helpers

// swiftlint:disable large_tuple
@MainActor
private func createMorningBriefingSUT(
    isPremium: Bool = true,
    notificationStatus: NotificationAuthorizationStatus = .authorized
) -> (SettingsDomainInteractor, MockSettingsService, MockNotificationService) {
    let mockSettingsService = MockSettingsService()
    let mockNotificationService = MockNotificationService()
    mockNotificationService.authorizationStatusResult = notificationStatus
    let serviceLocator = ServiceLocator()
    serviceLocator.register(SettingsService.self, instance: mockSettingsService)
    serviceLocator.register(AnalyticsService.self, instance: MockAnalyticsService())
    serviceLocator.register(NotificationService.self, instance: mockNotificationService)
    serviceLocator.register(StoreKitService.self, instance: MockStoreKitService(isPremium: isPremium))
    return (
        SettingsDomainInteractor(serviceLocator: serviceLocator),
        mockSettingsService, mockNotificationService
    )
}

// swiftlint:enable large_tuple

@Suite("SettingsDomainInteractor Morning Briefing Tests")
@MainActor
struct SettingsMorningBriefingTests {
    @Test("Enabling schedules the notification and persists the preference")
    func enablingSchedulesNotification() async throws {
        let (sut, mock, notificationService) = createMorningBriefingSUT()
        mock.preferences = .default
        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 200_000_000)

        sut.dispatch(action: .toggleMorningBriefing(true))
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.currentState.preferences.morningBriefingEnabled)
        #expect(notificationService.scheduleMorningBriefingCallCount == 1)
        #expect(notificationService.lastScheduledMorningBriefingTime?.hour == 7)
        #expect(notificationService.lastScheduledMorningBriefingTime?.minute == 0)
    }

    @Test("Enabling is blocked at the service boundary when not premium")
    func enablingBlockedWhenNotPremium() async throws {
        let (sut, mock, notificationService) = createMorningBriefingSUT(isPremium: false)
        mock.preferences = .default
        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 200_000_000)

        sut.dispatch(action: .toggleMorningBriefing(true))
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(!sut.currentState.preferences.morningBriefingEnabled)
        #expect(notificationService.scheduleMorningBriefingCallCount == 0)
    }

    @Test("Enabling with denied OS authorization shows the denied alert instead of scheduling")
    func enablingWithDeniedAuthorizationShowsAlert() async throws {
        let (sut, mock, notificationService) = createMorningBriefingSUT(notificationStatus: .denied)
        mock.preferences = .default
        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 200_000_000)

        sut.dispatch(action: .toggleMorningBriefing(true))
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(!sut.currentState.preferences.morningBriefingEnabled)
        #expect(sut.currentState.showNotificationsDeniedAlert)
        #expect(notificationService.scheduleMorningBriefingCallCount == 0)
    }

    @Test("Disabling cancels the notification and persists the preference")
    func disablingCancelsNotification() async throws {
        let (sut, mock, notificationService) = createMorningBriefingSUT()
        mock.preferences = UserPreferences(
            followedTopics: [], mutedSources: [], mutedKeywords: [],
            preferredLanguage: "en", notificationsEnabled: true, breakingNewsNotifications: true,
            morningBriefingEnabled: true, morningBriefingHour: 7, morningBriefingMinute: 0
        )
        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 200_000_000)

        sut.dispatch(action: .toggleMorningBriefing(false))
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(!sut.currentState.preferences.morningBriefingEnabled)
        #expect(notificationService.cancelMorningBriefingCallCount == 1)
    }

    @Test("Changing time while enabled reschedules with the new time")
    func changingTimeWhileEnabledReschedules() async throws {
        let (sut, mock, notificationService) = createMorningBriefingSUT()
        mock.preferences = UserPreferences(
            followedTopics: [], mutedSources: [], mutedKeywords: [],
            preferredLanguage: "en", notificationsEnabled: true, breakingNewsNotifications: true,
            morningBriefingEnabled: true, morningBriefingHour: 7, morningBriefingMinute: 0
        )
        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 200_000_000)

        sut.dispatch(action: .changeMorningBriefingTime(hour: 8, minute: 30))
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.currentState.preferences.morningBriefingHour == 8)
        #expect(sut.currentState.preferences.morningBriefingMinute == 30)
        #expect(notificationService.scheduleMorningBriefingCallCount == 1)
        #expect(notificationService.lastScheduledMorningBriefingTime?.hour == 8)
        #expect(notificationService.lastScheduledMorningBriefingTime?.minute == 30)
    }

    @Test("Changing time while disabled persists but does not reschedule")
    func changingTimeWhileDisabledDoesNotReschedule() async throws {
        let (sut, mock, notificationService) = createMorningBriefingSUT()
        mock.preferences = .default
        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 200_000_000)

        sut.dispatch(action: .changeMorningBriefingTime(hour: 8, minute: 30))
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.currentState.preferences.morningBriefingHour == 8)
        #expect(notificationService.scheduleMorningBriefingCallCount == 0)
    }

    @Test("Changing article count persists the preference without touching scheduling")
    func changingArticleCountPersists() async throws {
        let (sut, mock, notificationService) = createMorningBriefingSUT()
        mock.preferences = UserPreferences(
            followedTopics: [], mutedSources: [], mutedKeywords: [],
            preferredLanguage: "en", notificationsEnabled: true, breakingNewsNotifications: true,
            morningBriefingEnabled: true, morningBriefingHour: 7, morningBriefingMinute: 0,
            morningBriefingArticleCount: 10
        )
        sut.dispatch(action: .loadPreferences)
        try await Task.sleep(nanoseconds: 200_000_000)

        sut.dispatch(action: .changeMorningBriefingArticleCount(5))
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.currentState.preferences.morningBriefingArticleCount == 5)
        #expect(notificationService.scheduleMorningBriefingCallCount == 0)
    }
}
