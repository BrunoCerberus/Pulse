import Foundation

// MARK: - Constants

enum MutedContentConstants {
    static var contentFilters: String {
        AppLocalization.localized("settings.content_filters")
    }

    static var contentFiltersDescription: String {
        AppLocalization.localized("settings.content_filters.description")
    }

    static var mutedSources: String {
        AppLocalization.localized("settings.muted_sources")
    }

    static var addSource: String {
        AppLocalization.localized("settings.muted_sources.add")
    }

    static var addSourceAction: String {
        AppLocalization.localized("settings.muted_sources.add_action")
    }

    static var removeSourceAction: String {
        AppLocalization.localized("settings.muted_sources.remove_action")
    }

    static var mutedKeywords: String {
        AppLocalization.localized("settings.muted_keywords")
    }

    static var addKeyword: String {
        AppLocalization.localized("settings.muted_keywords.add")
    }

    static var addKeywordAction: String {
        AppLocalization.localized("settings.muted_keywords.add_action")
    }

    static var removeKeywordAction: String {
        AppLocalization.localized("settings.muted_keywords.remove_action")
    }
}
