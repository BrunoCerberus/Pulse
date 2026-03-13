import Foundation

// MARK: - Constants

enum SourceArticlesConstants {
    static var sectionTitle: String {
        AppLocalization.localized("digest.source_articles")
    }

    static var expanded: String {
        AppLocalization.localized("source_articles.expanded")
    }

    static var collapsed: String {
        AppLocalization.localized("source_articles.collapsed")
    }

    static var collapseHint: String {
        AppLocalization.localized("source_articles.collapse_hint")
    }

    static var expandHint: String {
        AppLocalization.localized("source_articles.expand_hint")
    }

    static var articleAccessibilityLabel: String {
        AppLocalization.localized("article_row.accessibility_label")
    }

    static var readArticleHint: String {
        AppLocalization.localized("accessibility.read_article")
    }
}
