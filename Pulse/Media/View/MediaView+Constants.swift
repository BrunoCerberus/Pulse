import Foundation

// MARK: - Constants

extension MediaView {
    enum Constants {
        static var title: String {
            AppLocalization.localized("media.title")
        }

        static var featured: String {
            AppLocalization.localized("media.featured")
        }

        static var latest: String {
            AppLocalization.localized("media.latest")
        }

        static var all: String {
            AppLocalization.localized("media.all_types")
        }

        static var errorTitle: String {
            AppLocalization.localized("media.error.title")
        }

        static var emptyTitle: String {
            AppLocalization.localized("media.empty.title")
        }

        static var emptyMessage: String {
            AppLocalization.localized("media.empty.message")
        }

        static var offlineTitle: String {
            AppLocalization.localized("media.offline.title")
        }

        static var offlineMessage: String {
            AppLocalization.localized("media.offline.message")
        }

        static var tryAgain: String {
            AppLocalization.localized("common.try_again")
        }

        static var loadingMore: String {
            AppLocalization.localized("common.loading_more")
        }
    }
}
