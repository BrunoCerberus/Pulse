import Foundation

extension ForYouCarouselView {
    enum Constants {
        /// Static `var` (not `let`) so runtime language switches re-resolve
        /// — see the `AppLocalization` rule in `MEMORY.md`.
        static var sectionTitle: String {
            AppLocalization.localized("for_you.title")
        }

        static var whyThis: String {
            AppLocalization.localized("for_you.why_this")
        }

        static var matchedPrefix: String {
            AppLocalization.localized("for_you.matched_prefix")
        }

        static var loadingLabel: String {
            AppLocalization.localized("for_you.loading")
        }
    }
}
