import Foundation

final class LiveOnboardingService: OnboardingService {
    private static let key = "pulse.hasCompletedOnboarding"

    var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: Self.key) }
        set { UserDefaults.standard.set(newValue, forKey: Self.key) }
    }
}
