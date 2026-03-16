import Foundation

// MARK: - Constants

extension FeedView {
    enum Constants {
        static var title: String {
            AppLocalization.localized("feed.title")
        }

        static var headerTitle: String {
            AppLocalization.localized("feed.header_title")
        }

        static var emptyTitle: String {
            AppLocalization.localized("feed.empty.title")
        }

        static var emptyMessage: String {
            AppLocalization.localized("feed.empty.message")
        }

        static var errorTitle: String {
            AppLocalization.localized("feed.error.title")
        }

        static var tryAgain: String {
            AppLocalization.localized("common.try_again")
        }

        static var startReading: String {
            AppLocalization.localized("feed.start_reading")
        }

        static var offlineTitle: String {
            AppLocalization.localized("feed.offline.title")
        }

        static var offlineMessage: String {
            AppLocalization.localized("feed.offline.message")
        }

        static var digestReady: String {
            AppLocalization.localized("accessibility.digest_ready")
        }

        static var retryHint: String {
            AppLocalization.localized("feed.retry_hint")
        }
    }
}
