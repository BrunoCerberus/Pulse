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
    let sut: OnboardingDomainInteractor

    init() {
        let serviceLocator = ServiceLocator()
        mockOnboardingService = MockOnboardingService()
        mockAnalyticsService = MockAnalyticsService()

        serviceLocator.register(OnboardingService.self, instance: mockOnboardingService)
        serviceLocator.register(AnalyticsService.self, instance: mockAnalyticsService)

        sut = OnboardingDomainInteractor(serviceLocator: serviceLocator)
    }

    @Test("Initial state starts on welcome page")
    func initialState() {
        #expect(sut.currentState.currentPage == .welcome)
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

        #expect(mockAnalyticsService.loggedEvents.count == 1)
        if case let .onboardingCompleted(page) = mockAnalyticsService.loggedEvents.first {
            #expect(page == OnboardingPage.getStarted.rawValue)
        } else {
            Issue.record("Expected onboardingCompleted event")
        }
    }
}
