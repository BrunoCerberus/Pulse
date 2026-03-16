import Foundation

// MARK: - Constants

extension GlassArticleCard {
    enum Constants {
        static var accessibilityLabelFormat: String {
            AppLocalization.localized("article_row.accessibility_label")
        }

        static var accessibilityHint: String {
            AppLocalization.localized("accessibility.read_article")
        }

        static var removeBookmark: String {
            AppLocalization.localized("article.remove_bookmark")
        }

        static var bookmark: String {
            AppLocalization.localized("article.bookmark")
        }

        static var share: String {
            AppLocalization.localized("article.share")
        }
    }
}
