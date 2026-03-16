import Foundation

// MARK: - Constants

extension SignInView {
    enum Constants {
        static var appName: String {
            AppLocalization.localized("app.name")
        }

        static var tagline: String {
            AppLocalization.localized("auth.tagline")
        }

        static var signInApple: String {
            AppLocalization.localized("auth.sign_in_apple")
        }

        static var signInGoogle: String {
            AppLocalization.localized("auth.sign_in_google")
        }

        static var terms: String {
            AppLocalization.localized("auth.terms")
        }

        static var signingIn: String {
            AppLocalization.localized("auth.signing_in")
        }

        static var error: String {
            AppLocalization.localized("common.error")
        }

        static var okButton: String {
            AppLocalization.localized("common.ok")
        }

        static var unknownError: String {
            AppLocalization.localized("auth.unknown_error")
        }

        static var appleHint: String {
            AppLocalization.localized("auth.apple_hint")
        }

        static var googleHint: String {
            AppLocalization.localized("auth.google_hint")
        }
    }
}
