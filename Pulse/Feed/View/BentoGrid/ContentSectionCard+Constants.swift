import SwiftUI

// MARK: - Constants

extension ContentSectionCard {
    enum Constants {
        static let featuredImageHeight: CGFloat = 140
        static let featuredImageCornerRadius: CGFloat = 12

        static var articleCountOne: String {
            AppLocalization.localized("digest.article_count_one")
        }

        static var articleCountOther: String {
            AppLocalization.localized("digest.article_count_other")
        }

        static var articleAccessibilityLabel: String {
            AppLocalization.localized("article_row.accessibility_label")
        }

        static var readArticleHint: String {
            AppLocalization.localized("accessibility.read_article")
        }

        static var relatedArticles: String {
            AppLocalization.localized("digest.related_articles")
        }
    }
}
