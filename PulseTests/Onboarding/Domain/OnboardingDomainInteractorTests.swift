import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("OnboardingDomainInteractor Tests")
@MainActor
struct OnboardingDomainInteractorTests {
    let mockOnboardingService: MockOnboardingService
    let mockAnalyticsService: MockAnalyticsService
    let mockSettingsService: MockSettingsService
    let sut: OnboardingDomainInteractor

    init() {
        let serviceLocator = ServiceLocator()
        mockOnboardingService = MockOnboardingService()
        mockAnalyticsService = MockAnalyticsService()
        mockSettingsService = MockSettingsService()

        serviceLocator.register(OnboardingService.self, instance: mockOnboardingService)
        serviceLocator.register(AnalyticsService.self, instance: mockAnalyticsService)
        serviceLocator.register(SettingsService.self, instance: mockSettingsService)

        sut = OnboardingDomainInteractor(serviceLocator: serviceLocator)
    }

    @Test("Initial state starts on welcome page")
    func initialState() {
        #expect(sut.currentState.currentPage == .welcome)
        #expect(sut.currentState.selectedTopics.isEmpty)
        #expect(sut.currentState.isCompleted == false)
    }

    @Test("nextPage advances from welcome to aiPowered")
    func nextPageFromWelcome() {
        sut.dispatch(action: .nextPage)
        #expect(sut.currentState.currentPage == .aiPowered)
    }

    @Test("nextPage advances through all pages in order")
    func nextPageSequence() {
        sut.dispatch(action: .nextPage)
        #expect(sut.currentState.currentPage == .aiPowered)

        sut.dispatch(action: .nextPage)
        #expect(sut.currentState.currentPage == .stayConnected)

        sut.dispatch(action: .nextPage)
        #expect(sut.currentState.currentPage == .chooseTopics)

        sut.dispatch(action: .nextPage)
        #expect(sut.currentState.currentPage == .getStarted)
    }

    @Test("nextPage on last page triggers completion")
    func nextPageOnLastPage() {
        sut.dispatch(action: .goToPage(.getStarted))
        sut.dispatch(action: .nextPage)

        #expect(sut.currentState.isCompleted == true)
        #expect(mockOnboardingService.hasCompletedOnboarding == true)
    }

    @Test("goToPage navigates to specific page")
    func goToPage() {
        sut.dispatch(action: .goToPage(.stayConnected))
        #expect(sut.currentState.currentPage == .stayConnected)
    }

    @Test("skip marks onboarding as completed")
    func skip() {
        sut.dispatch(action: .skip)

        #expect(sut.currentState.isCompleted == true)
        #expect(mockOnboardingService.hasCompletedOnboarding == true)
    }

    @Test("skip logs onboardingSkipped analytics event")
    func skipAnalytics() {
        sut.dispatch(action: .goToPage(.aiPowered))
        sut.dispatch(action: .skip)

        #expect(mockAnalyticsService.loggedEvents.count == 1)
        if case let .onboardingSkipped(page) = mockAnalyticsService.loggedEvents.first {
            #expect(page == OnboardingPage.aiPowered.rawValue)
        } else {
            Issue.record("Expected onboardingSkipped event")
        }
    }

    @Test("complete logs onboardingCompleted analytics event")
    func completeAnalytics() {
        sut.dispatch(action: .goToPage(.getStarted))
        sut.dispatch(action: .nextPage)

        #expect(mockAnalyticsService.loggedEvents.contains { event in
            if case let .onboardingCompleted(page) = event {
                return page == OnboardingPage.getStarted.rawValue
            }
            return false
        })
    }

    // MARK: - Topic Selection

    @Test("toggleTopic adds topic when not selected")
    func toggleTopicAdds() {
        sut.dispatch(action: .toggleTopic(.technology))
        #expect(sut.currentState.selectedTopics == [.technology])
    }

    @Test("toggleTopic removes topic when already selected")
    func toggleTopicRemoves() {
        sut.dispatch(action: .toggleTopic(.technology))
        sut.dispatch(action: .toggleTopic(.technology))
        #expect(sut.currentState.selectedTopics.isEmpty)
    }

    @Test("toggleTopic can accumulate multiple selections")
    func toggleTopicMultiple() {
        sut.dispatch(action: .toggleTopic(.technology))
        sut.dispatch(action: .toggleTopic(.science))
        sut.dispatch(action: .toggleTopic(.business))
        #expect(sut.currentState.selectedTopics == [.technology, .science, .business])
    }

    @Test("complete persists selected topics to SettingsService")
    func completePersistsTopics() async throws {
        sut.dispatch(action: .toggleTopic(.technology))
        sut.dispatch(action: .toggleTopic(.science))
        sut.dispatch(action: .goToPage(.getStarted))
        sut.dispatch(action: .nextPage)

        try await waitForStateUpdate(duration: TestWaitDuration.short)

        #expect(Set(mockSettingsService.preferences.followedTopics) == [.technology, .science])
    }

    @Test("complete persists topics in declaration order")
    func completePersistsTopicsInDeclarationOrder() async throws {
        sut.dispatch(action: .toggleTopic(.sports))
        sut.dispatch(action: .toggleTopic(.business))
        sut.dispatch(action: .toggleTopic(.world))
        sut.dispatch(action: .goToPage(.getStarted))
        sut.dispatch(action: .nextPage)

        try await waitForStateUpdate(duration: TestWaitDuration.short)

        #expect(mockSettingsService.preferences.followedTopics == [.world, .business, .sports])
    }

    @Test("complete with no topics selected does not overwrite preferences")
    func completeWithNoTopicsLeavesPrefsAlone() async throws {
        let original = mockSettingsService.preferences

        sut.dispatch(action: .goToPage(.getStarted))
        sut.dispatch(action: .nextPage)

        try await waitForStateUpdate(duration: TestWaitDuration.short)

        #expect(mockSettingsService.preferences == original)
    }

    @Test("skip does not persist selected topics")
    func skipDoesNotPersist() async throws {
        let original = mockSettingsService.preferences

        sut.dispatch(action: .toggleTopic(.technology))
        sut.dispatch(action: .skip)

        try await waitForStateUpdate(duration: TestWaitDuration.short)

        #expect(mockSettingsService.preferences == original)
    }

    @Test("complete with topics logs onboardingTopicsSelected analytics event")
    func completeLogsTopicsAnalytics() async throws {
        sut.dispatch(action: .toggleTopic(.technology))
        sut.dispatch(action: .toggleTopic(.health))
        sut.dispatch(action: .goToPage(.getStarted))
        sut.dispatch(action: .nextPage)

        try await waitForStateUpdate(duration: TestWaitDuration.short)

        let event = mockAnalyticsService.loggedEvents.first { event in
            if case .onboardingTopicsSelected = event { return true }
            return false
        }
        guard case let .onboardingTopicsSelected(count, topics) = event else {
            Issue.record("Expected onboardingTopicsSelected event")
            return
        }
        #expect(count == 2)
        #expect(topics == ["health", "technology"])
    }

    @Test("complete with no topics does not log onboardingTopicsSelected analytics event")
    func completeWithoutTopicsDoesNotLogAnalytics() async throws {
        sut.dispatch(action: .goToPage(.getStarted))
        sut.dispatch(action: .nextPage)

        try await waitForStateUpdate(duration: TestWaitDuration.short)

        let hasTopicsEvent = mockAnalyticsService.loggedEvents.contains { event in
            if case .onboardingTopicsSelected = event { return true }
            return false
        }
        #expect(hasTopicsEvent == false)
    }

    @Test("complete preserves other fields when persisting topic selection")
    func completePreservesOtherPreferenceFields() async throws {
        mockSettingsService.preferences = UserPreferences(
            followedTopics: [],
            mutedSources: ["source1"],
            mutedKeywords: ["keyword1"],
            preferredLanguage: "pt",
            notificationsEnabled: false,
            breakingNewsNotifications: false
        )

        // Rebuild sut so the new preference seed is loaded on init.
        let serviceLocator = ServiceLocator()
        serviceLocator.register(OnboardingService.self, instance: mockOnboardingService)
        serviceLocator.register(AnalyticsService.self, instance: mockAnalyticsService)
        serviceLocator.register(SettingsService.self, instance: mockSettingsService)
        let freshSut = OnboardingDomainInteractor(serviceLocator: serviceLocator)

        try await waitForStateUpdate(duration: TestWaitDuration.short)

        freshSut.dispatch(action: .toggleTopic(.technology))
        freshSut.dispatch(action: .goToPage(.getStarted))
        freshSut.dispatch(action: .nextPage)

        try await waitForStateUpdate(duration: TestWaitDuration.short)

        #expect(mockSettingsService.preferences.followedTopics == [.technology])
        #expect(mockSettingsService.preferences.mutedSources == ["source1"])
        #expect(mockSettingsService.preferences.mutedKeywords == ["keyword1"])
        #expect(mockSettingsService.preferences.preferredLanguage == "pt")
        #expect(mockSettingsService.preferences.notificationsEnabled == false)
        #expect(mockSettingsService.preferences.breakingNewsNotifications == false)
    }

    @Test("pre-populates selectedTopics from restored preferences")
    func prePopulatesSelectedTopics() async throws {
        mockSettingsService.preferences = UserPreferences(
            followedTopics: [.science, .technology],
            mutedSources: [],
            mutedKeywords: [],
            preferredLanguage: "en",
            notificationsEnabled: true,
            breakingNewsNotifications: true
        )

        let serviceLocator = ServiceLocator()
        serviceLocator.register(OnboardingService.self, instance: mockOnboardingService)
        serviceLocator.register(AnalyticsService.self, instance: mockAnalyticsService)
        serviceLocator.register(SettingsService.self, instance: mockSettingsService)
        let freshSut = OnboardingDomainInteractor(serviceLocator: serviceLocator)

        try await waitForStateUpdate(duration: TestWaitDuration.short)

        #expect(freshSut.currentState.selectedTopics == [.science, .technology])
    }

    @Test("user interaction is not clobbered by late-arriving preferences")
    func userInteractionWinsOverLatePreferences() async throws {
        mockSettingsService.preferences = UserPreferences(
            followedTopics: [.science, .technology],
            mutedSources: [],
            mutedKeywords: [],
            preferredLanguage: "en",
            notificationsEnabled: true,
            breakingNewsNotifications: true
        )
        mockSettingsService.fetchPreferencesDelay = 0.1

        let serviceLocator = ServiceLocator()
        serviceLocator.register(OnboardingService.self, instance: mockOnboardingService)
        serviceLocator.register(AnalyticsService.self, instance: mockAnalyticsService)
        serviceLocator.register(SettingsService.self, instance: mockSettingsService)
        let freshSut = OnboardingDomainInteractor(serviceLocator: serviceLocator)

        // User taps before preferences arrive
        freshSut.dispatch(action: .toggleTopic(.health))

        // Wait past the fetch delay so the pre-populate branch would have fired
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(freshSut.currentState.selectedTopics == [.health])
    }
}
