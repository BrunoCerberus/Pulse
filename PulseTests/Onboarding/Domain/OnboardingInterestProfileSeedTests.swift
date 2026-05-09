import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("Onboarding Interest Profile Seed Tests")
@MainActor
struct OnboardingInterestProfileSeedTests {
    let mockOnboardingService: MockOnboardingService
    let mockSettingsService: MockSettingsService
    let mockProfileService: MockInterestProfileService
    let sut: OnboardingDomainInteractor

    init() {
        let serviceLocator = ServiceLocator()
        mockOnboardingService = MockOnboardingService()
        mockSettingsService = MockSettingsService()
        mockProfileService = MockInterestProfileService()

        serviceLocator.register(OnboardingService.self, instance: mockOnboardingService)
        serviceLocator.register(AnalyticsService.self, instance: MockAnalyticsService())
        serviceLocator.register(SettingsService.self, instance: mockSettingsService)
        serviceLocator.register(InterestProfileService.self, instance: mockProfileService)

        sut = OnboardingDomainInteractor(serviceLocator: serviceLocator)
    }

    @Test("Completing onboarding with topics seeds the interest profile")
    func completionSeedsProfile() async {
        sut.dispatch(action: .toggleTopic(.technology))
        sut.dispatch(action: .toggleTopic(.science))
        sut.dispatch(action: .complete)

        let seeded = await waitForCondition(timeout: TestWaitDuration.long) { [mockProfileService] in
            mockProfileService.topics.count == 2
        }
        #expect(seeded)
        #expect(Set(mockProfileService.topics.map(\.topicID)) == ["technology", "science"])
        #expect(mockProfileService.topics.allSatisfy { $0.source == .seed })
    }

    @Test("Completing onboarding with no topics does not seed the profile")
    func completionWithoutTopicsDoesNotSeed() async throws {
        sut.dispatch(action: .complete)
        try await waitForStateUpdate(duration: TestWaitDuration.long)
        #expect(mockProfileService.topics.isEmpty)
    }

    @Test("Skipping onboarding does not seed the profile")
    func skipDoesNotSeed() async throws {
        sut.dispatch(action: .toggleTopic(.technology))
        sut.dispatch(action: .skip)
        try await waitForStateUpdate(duration: TestWaitDuration.long)
        #expect(mockProfileService.topics.isEmpty)
    }
}
