import Foundation

/// Centralized legal URLs exposed in sign-in, paywall, and settings.
///
/// These URLs MUST resolve to published, human-readable pages before App Store
/// submission. App Review Guideline 3.1.2 requires functional Privacy Policy
/// and Terms of Use links on every auto-renewable subscription surface.
enum LegalURLs {
    static let privacyPolicy = URL(string: "https://brunocerberus.github.io/Pulse/privacy-policy.html")!
    static let termsOfService = URL(string: "https://brunocerberus.github.io/Pulse/terms-of-service.html")!
    static let support = URL(string: "https://brunocerberus.github.io/Pulse/support.html")!
}
