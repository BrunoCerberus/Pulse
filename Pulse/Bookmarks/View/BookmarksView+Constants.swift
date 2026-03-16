import Foundation

// MARK: - Constants

extension BookmarksView {
    enum Constants {
        static var title: String {
            AppLocalization.localized("bookmarks.title")
        }

        static var loading: String {
            AppLocalization.localized("bookmarks.loading")
        }

        static var errorTitle: String {
            AppLocalization.localized("bookmarks.error.title")
        }

        static var emptyTitle: String {
            AppLocalization.localized("bookmarks.empty.title")
        }

        static var emptyMessage: String {
            AppLocalization.localized("bookmarks.empty.message")
        }

        static var tryAgain: String {
            AppLocalization.localized("common.try_again")
        }

        static var savedCount: String {
            AppLocalization.localized("bookmarks.saved_count")
        }
    }
}
