import Foundation

final class MockOnboardingService: OnboardingService {
    var hasCompletedOnboarding: Bool

    init(hasCompletedOnboarding: Bool = false) {
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }
}
