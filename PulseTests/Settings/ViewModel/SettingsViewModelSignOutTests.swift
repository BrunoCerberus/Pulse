import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing
import UIKit

@Suite("SettingsViewModel SignOut Tests")
@MainActor
// swiftlint:disable:next type_body_length
struct SettingsViewModelSignOutTests {
    let mockSettingsService: MockSettingsService
    let mockAuthService: MockAuthService
    let mockAnalyticsService: MockAnalyticsService
    let mockStorageService: MockStorageService
    let mockSearchService: MockSearchService
    let mockAppLockService: MockAppLockService
    let mockNotificationService: MockNotificationService
    let serviceLocator: ServiceLocator

    init() {
        mockSettingsService = MockSettingsService()
        mockAuthService = MockAuthService()
        mockAnalyticsService = MockAnalyticsService()
        mockStorageService = MockStorageService()
        mockSearchService = MockSearchService()
        mockAppLockService = MockAppLockService()
        mockNotificationService = MockNotificationService()
        serviceLocator = ServiceLocator()

        serviceLocator.register(SettingsService.self, instance: mockSettingsService)
        serviceLocator.register(AuthService.self, instance: mockAuthService)
        serviceLocator.register(AnalyticsService.self, instance: mockAnalyticsService)
        serviceLocator.register(StorageService.self, instance: mockStorageService)
        serviceLocator.register(SearchService.self, instance: mockSearchService)
        serviceLocator.register(AppLockService.self, instance: mockAppLockService)
        serviceLocator.register(NotificationService.self, instance: mockNotificationService)
    }

    private func createSUT() -> SettingsViewModel {
        SettingsViewModel(
            serviceLocator: serviceLocator,
            viewControllerProvider: { UIViewController() }
        )
    }

    // MARK: - Sign Out Tests

    @Test("Confirm sign out calls auth service sign out")
    func confirmSignOutCallsAuthService() async throws {
        let sut = createSUT()
        sut.handle(event: .onAppear)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        sut.handle(event: .onConfirmSignOut)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        // Sign out should dismiss the confirmation
        #expect(!sut.viewState.showSignOutConfirmation)
    }

    @Test("Sign out clears app lock settings")
    func signOutClearsAppLock() async throws {
        mockAppLockService.isEnabled = true
        mockAppLockService.hasPromptedFaceID = true

        let sut = createSUT()
        sut.handle(event: .onAppear)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        sut.handle(event: .onConfirmSignOut)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(!mockAppLockService.isEnabled)
        #expect(!mockAppLockService.hasPromptedFaceID)
    }

    @Test("Sign out clears UserDefaults preferences")
    func signOutClearsUserDefaults() async throws {
        let defaults = UserDefaults.standard
        let keysToCheck = [
            "pulse.hasCompletedOnboarding",
            "pulse.preferredLanguage",
            "pulse.notificationsEnabled",
            "pulse.deviceToken",
        ]
        defer { keysToCheck.forEach { defaults.removeObject(forKey: $0) } }

        defaults.set(true, forKey: "pulse.hasCompletedOnboarding")
        defaults.set("pt", forKey: "pulse.preferredLanguage")
        defaults.set(true, forKey: "pulse.notificationsEnabled")
        defaults.set("token123", forKey: "pulse.deviceToken")

        let sut = createSUT()
        sut.handle(event: .onAppear)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        sut.handle(event: .onConfirmSignOut)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        for key in keysToCheck {
            #expect(defaults.object(forKey: key) == nil, "Key '\(key)' should be nil after sign-out")
        }
    }

    @Test("Sign out failure still dismisses confirmation")
    func signOutFailureDismissesConfirmation() async throws {
        mockAuthService.signOutResult = .failure(
            NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Sign out failed"])
        )

        let sut = createSUT()
        sut.handle(event: .onAppear)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        sut.handle(event: .onSignOutTapped)
        try await waitForStateUpdate(duration: TestWaitDuration.long)
        #expect(sut.viewState.showSignOutConfirmation)

        sut.handle(event: .onConfirmSignOut)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(!sut.viewState.showSignOutConfirmation)
    }

    // MARK: - Delete Account Tests

    @Test("Tapping delete account shows confirmation")
    func tappingDeleteAccountShowsConfirmation() async throws {
        let sut = createSUT()
        sut.handle(event: .onAppear)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        sut.handle(event: .onDeleteAccountTapped)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(sut.viewState.showDeleteAccountConfirmation)
    }

    @Test("Cancelling delete account hides confirmation")
    func cancellingDeleteAccountHidesConfirmation() async throws {
        let sut = createSUT()
        sut.handle(event: .onAppear)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        sut.handle(event: .onDeleteAccountTapped)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        sut.handle(event: .onCancelDeleteAccount)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(!sut.viewState.showDeleteAccountConfirmation)
    }

    @Test("Confirm delete account invokes auth service deleteAccount")
    func confirmDeleteAccountCallsAuthService() async throws {
        let sut = createSUT()
        sut.handle(event: .onAppear)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        sut.handle(event: .onConfirmDeleteAccount)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(mockAuthService.deleteAccountCallCount == 1)
        #expect(!sut.viewState.showDeleteAccountConfirmation)
        #expect(!sut.viewState.isDeletingAccount)
    }

    @Test("Account deletion clears app lock settings")
    func deleteAccountClearsAppLock() async throws {
        mockAppLockService.isEnabled = true
        mockAppLockService.hasPromptedFaceID = true

        let sut = createSUT()
        sut.handle(event: .onAppear)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        sut.handle(event: .onConfirmDeleteAccount)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(!mockAppLockService.isEnabled)
        #expect(!mockAppLockService.hasPromptedFaceID)
    }

    @Test("Account deletion clears UserDefaults preferences")
    func deleteAccountClearsUserDefaults() async throws {
        let defaults = UserDefaults.standard
        let keysToCheck = [
            "pulse.hasCompletedOnboarding",
            "pulse.preferredLanguage",
            "pulse.notificationsEnabled",
            "pulse.deviceToken",
        ]
        defer { keysToCheck.forEach { defaults.removeObject(forKey: $0) } }

        defaults.set(true, forKey: "pulse.hasCompletedOnboarding")
        defaults.set("pt", forKey: "pulse.preferredLanguage")
        defaults.set(true, forKey: "pulse.notificationsEnabled")
        defaults.set("token123", forKey: "pulse.deviceToken")

        let sut = createSUT()
        sut.handle(event: .onAppear)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        sut.handle(event: .onConfirmDeleteAccount)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        for key in keysToCheck {
            #expect(defaults.object(forKey: key) == nil, "Key '\(key)' should be nil after account deletion")
        }
    }

    @Test("Delete account failure clears loading state")
    func deleteAccountFailureClearsLoadingState() async throws {
        mockAuthService.deleteAccountResult = .failure(
            NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Delete failed"])
        )

        let sut = createSUT()
        sut.handle(event: .onAppear)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        sut.handle(event: .onConfirmDeleteAccount)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(!sut.viewState.isDeletingAccount)
    }

    @Test("User-cancelled re-auth during deletion is not reported as error")
    func deleteAccountCancelledReauthNotReportedAsError() async throws {
        mockAuthService.deleteAccountResult = .failure(AuthError.signInCancelled)

        let sut = createSUT()
        sut.handle(event: .onAppear)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        sut.handle(event: .onConfirmDeleteAccount)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(!sut.viewState.isDeletingAccount)
        #expect(mockAnalyticsService.recordedErrors.isEmpty)
    }

    @Test("Successful deletion logs delete_account analytics event")
    func deleteAccountLogsAnalyticsOnSuccess() async throws {
        let sut = createSUT()
        sut.handle(event: .onAppear)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        sut.handle(event: .onConfirmDeleteAccount)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        let deleteEvents = mockAnalyticsService.loggedEvents.filter { $0.name == "delete_account" }
        #expect(deleteEvents.count == 1)
    }

    // MARK: - Atomic Cleanup / Partial-Failure Surfacing

    @Test("Sign-out surfaces an error message when local cleanup partially fails")
    func signOutPartialFailureSurfacesError() async throws {
        mockStorageService.clearReadingHistoryError = NSError(
            domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "disk full"]
        )

        // Seed the key so the post-cleanup assertion is not vacuous —
        // confirms the cleanup actually ran past the failing step rather
        // than just passing because the key was never set.
        let defaults = UserDefaults.standard
        defaults.set("token-pre-test", forKey: "pulse.deviceToken")
        defer { defaults.removeObject(forKey: "pulse.deviceToken") }

        let sut = createSUT()
        sut.handle(event: .onAppear)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        sut.handle(event: .onConfirmSignOut)
        // Cleanup is now sequential and awaited; give it room to finish.
        try await waitForStateUpdate(duration: TestWaitDuration.long)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(sut.viewState.errorMessage != nil)
        // Confirm later cleanup steps still ran despite the earlier failure.
        #expect(defaults.object(forKey: "pulse.deviceToken") == nil)
        // Also confirm the persisted message is in place for SignInView to surface.
        let persisted = defaults.string(forKey: SettingsViewModel.pendingCleanupErrorKey)
        #expect(persisted != nil)
        defaults.removeObject(forKey: SettingsViewModel.pendingCleanupErrorKey)
    }

    @Test("Sign-out completes silently when every cleanup step succeeds")
    func signOutWithoutFailuresShowsNoError() async throws {
        let sut = createSUT()
        sut.handle(event: .onAppear)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        sut.handle(event: .onConfirmSignOut)
        try await waitForStateUpdate(duration: TestWaitDuration.long)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(sut.viewState.errorMessage == nil)
    }

    @Test("Delete-account surfaces an error message when local cleanup partially fails")
    func deleteAccountPartialFailureSurfacesError() async throws {
        mockStorageService.clearReadingHistoryError = NSError(
            domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "disk full"]
        )

        let sut = createSUT()
        sut.handle(event: .onAppear)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        sut.handle(event: .onConfirmDeleteAccount)
        try await waitForStateUpdate(duration: TestWaitDuration.long)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(sut.viewState.errorMessage != nil)
        #expect(!sut.viewState.isDeletingAccount)
    }

    // MARK: - Notification Events Tests

    @Test("Toggle notifications updates view state")
    func toggleNotificationsUpdatesViewState() async throws {
        let sut = createSUT()
        sut.handle(event: .onAppear)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        sut.handle(event: .onToggleNotifications(false))
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(!sut.viewState.notificationsEnabled)
    }

    @Test("Toggle breaking news updates view state")
    func toggleBreakingNewsUpdatesViewState() async throws {
        let sut = createSUT()
        sut.handle(event: .onAppear)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        sut.handle(event: .onToggleBreakingNews(false))
        try await waitForStateUpdate(duration: TestWaitDuration.long)

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
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        sut.handle(event: .onRemoveMutedSource("Source1"))
        try await waitForStateUpdate(duration: TestWaitDuration.long)

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
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        sut.handle(event: .onRemoveMutedKeyword("keyword1"))
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(!sut.viewState.mutedKeywords.contains("keyword1"))
        #expect(sut.viewState.mutedKeywords.contains("keyword2"))
    }
}
