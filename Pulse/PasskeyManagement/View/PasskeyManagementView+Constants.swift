import Foundation

extension PasskeyManagementView {
    enum Constants {
        static var title: String {
            AppLocalization.localized("settings.passkeys.title")
        }

        static var okButton: String {
            AppLocalization.localized("common.ok")
        }

        static var error: String {
            AppLocalization.localized("common.error")
        }

        static var unknownError: String {
            AppLocalization.localized("auth.unknown_error")
        }

        static var accountLabel: String {
            AppLocalization.localized("settings.passkeys.account")
        }

        static var noPasskeysTitle: String {
            AppLocalization.localized("settings.passkeys.no_passkeys_title")
        }

        static var noPasskeysDescription: String {
            AppLocalization.localized("settings.passkeys.no_passkeys_description")
        }

        static var registerButton: String {
            AppLocalization.localized("settings.passkeys.register")
        }
    }
}
