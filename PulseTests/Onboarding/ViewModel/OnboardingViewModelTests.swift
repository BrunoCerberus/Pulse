import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("OnboardingViewModel Tests")
@MainActor
struct OnboardingViewModelTests {
    let sut: OnboardingViewModel

    init() {
        let serviceLocator = ServiceLocator()
        serviceLocator.register(OnboardingService.self, instance: MockOnboardingService())
        serviceLocator.register(AnalyticsService.self, instance: MockAnalyticsService())

        sut = OnboardingViewModel(serviceLocator: serviceLocator)
    }

    @Test("Initial view state has welcome page and is not last page")
    func initialViewState() async throws {
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        #expect(sut.viewState.currentPage == .welcome)
        #expect(sut.viewState.isLastPage == false)
        #expect(sut.viewState.isCompleted == false)
    }

    @Test("onNextTapped advances page")
    func onNextTapped() async throws {
        sut.handle(event: .onNextTapped)
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        #expect(sut.viewState.currentPage == .aiPowered)
        #expect(sut.viewState.isLastPage == false)
    }

    @Test("isLastPage is true on getStarted page")
    func isLastPage() async throws {
        sut.handle(event: .onPageChanged(.getStarted))
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        #expect(sut.viewState.isLastPage == true)
    }

    @Test("onSkipTapped completes onboarding")
    func onSkipTapped() async throws {
        sut.handle(event: .onSkipTapped)
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        #expect(sut.viewState.isCompleted == true)
    }

    @Test("onPageChanged updates current page")
    func onPageChanged() async throws {
        sut.handle(event: .onPageChanged(.stayConnected))
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        #expect(sut.viewState.currentPage == .stayConnected)
    }
}
