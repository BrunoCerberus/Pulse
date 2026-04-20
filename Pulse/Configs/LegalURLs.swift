import Foundation

/// Centralized legal URLs exposed in sign-in, paywall, and settings.
///
/// These URLs MUST resolve to published, human-readable pages before App Store
/// submission. App Review Guideline 3.1.2 requires functional Privacy Policy
/// and Terms of Use links on every auto-renewable subscription surface.
///
/// Force-unwrapping `URL(string:)` is intentional: these are hardcoded string
/// literals validated at development time, and a nil result here would be a
/// programmer error that should fail fast rather than silently degrade.
enum LegalURLs {
    // swiftlint:disable force_unwrapping
    static let privacyPolicy = URL(string: "https://brunocerberus.github.io/Pulse/privacy-policy.html")!
    static let termsOfService = URL(string: "https://brunocerberus.github.io/Pulse/terms-of-service.html")!
    static let support = URL(string: "https://brunocerberus.github.io/Pulse/support.html")!
    // swiftlint:enable force_unwrapping
}
