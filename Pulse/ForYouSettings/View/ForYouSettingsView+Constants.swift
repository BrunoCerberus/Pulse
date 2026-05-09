import Foundation

extension ForYouSettingsView {
    enum Constants {
        static var navigationTitle: String {
            AppLocalization.localized("for_you_settings.title")
        }

        static var headerSubtitle: String {
            AppLocalization.localized("for_you_settings.subtitle")
        }

        static var emptyTitle: String {
            AppLocalization.localized("for_you_settings.empty.title")
        }

        static var emptyMessage: String {
            AppLocalization.localized("for_you_settings.empty.message")
        }

        static var resetButton: String {
            AppLocalization.localized("for_you_settings.reset_button")
        }

        static var resetConfirmTitle: String {
            AppLocalization.localized("for_you_settings.reset_confirm.title")
        }

        static var resetConfirmMessage: String {
            AppLocalization.localized("for_you_settings.reset_confirm.message")
        }

        static var resetConfirmAction: String {
            AppLocalization.localized("for_you_settings.reset_confirm.action")
        }

        static var resetCancelAction: String {
            AppLocalization.localized("common.cancel")
        }

        static var deleteAction: String {
            AppLocalization.localized("common.delete")
        }

        static var sourceSeed: String {
            AppLocalization.localized("for_you_settings.source.seed")
        }

        static var sourceExtracted: String {
            AppLocalization.localized("for_you_settings.source.extracted")
        }

        static var sourceManual: String {
            AppLocalization.localized("for_you_settings.source.manual")
        }
    }
}
