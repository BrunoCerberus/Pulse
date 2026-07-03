import Foundation

// MARK: - Constants

extension SettingsView {
    enum Constants {
        static var title: String {
            AppLocalization.localized("settings.title")
        }

        static var personalizationHeader: String {
            AppLocalization.localized("settings.personalization.header")
        }

        static var personalizationRowTitle: String {
            AppLocalization.localized("settings.personalization.row.title")
        }

        static var personalizationRowSubtitle: String {
            AppLocalization.localized("settings.personalization.row.subtitle")
        }

        static var viewGithub: String {
            AppLocalization.localized("settings.view_github")
        }

        static var signOut: String {
            AppLocalization.localized("account.sign_out")
        }

        static var signOutConfirm: String {
            AppLocalization.localized("account.sign_out.confirm")
        }

        static var deleteAccountTitle: String {
            AppLocalization.localized("account.delete.title")
        }

        static var deleteAccountMessage: String {
            AppLocalization.localized("account.delete.message")
        }

        static var deleteAccountConfirm: String {
            AppLocalization.localized("account.delete.confirm")
        }

        static var cancel: String {
            AppLocalization.localized("common.cancel")
        }

        static var version: String {
            AppLocalization.localized("common.version")
        }

        static var notifications: String {
            AppLocalization.localized("settings.notifications")
        }

        static var enableNotifications: String {
            AppLocalization.localized("settings.enable_notifications")
        }

        static var breakingNewsAlerts: String {
            AppLocalization.localized("settings.breaking_news_alerts")
        }

        static var morningBriefing: String {
            AppLocalization.localized("settings.morning_briefing")
        }

        static var morningBriefingEnable: String {
            AppLocalization.localized("settings.morning_briefing.enable")
        }

        static var morningBriefingTime: String {
            AppLocalization.localized("settings.morning_briefing.time")
        }

        static var morningBriefingArticleCount: String {
            AppLocalization.localized("settings.morning_briefing.article_count")
        }

        static func morningBriefingArticleCountValue(_ count: Int) -> String {
            String(format: AppLocalization.localized("settings.morning_briefing.article_count_value"), count)
        }

        static var contentLanguage: String {
            AppLocalization.localized("settings.content_language")
        }

        static var contentLanguageLabel: String {
            AppLocalization.localized("settings.content_language.label")
        }

        static var appearance: String {
            AppLocalization.localized("settings.appearance")
        }

        static var useSystemTheme: String {
            AppLocalization.localized("settings.use_system_theme")
        }

        static var darkMode: String {
            AppLocalization.localized("settings.dark_mode")
        }

        static var data: String {
            AppLocalization.localized("settings.data")
        }

        static var readingHistory: String {
            AppLocalization.localized("settings.reading_history")
        }

        static var about: String {
            AppLocalization.localized("settings.about")
        }

        static var legal: String {
            AppLocalization.localized("legal.section")
        }

        static var privacyPolicy: String {
            AppLocalization.localized("legal.privacy_policy")
        }

        static var termsOfService: String {
            AppLocalization.localized("legal.terms_of_service")
        }
    }
}
