import Foundation

// MARK: - Constants

extension SearchView {
    enum Constants {
        static var title: String {
            AppLocalization.localized("search.title")
        }

        static var searching: String {
            AppLocalization.localized("search.searching")
        }

        static var placeholderTitle: String {
            AppLocalization.localized("search.placeholder.title")
        }

        static var placeholderMessage: String {
            AppLocalization.localized("search.placeholder.message")
        }

        static var errorTitle: String {
            AppLocalization.localized("search.error.title")
        }

        static var emptyTitle: String {
            AppLocalization.localized("search.empty.title")
        }

        static var tryAgain: String {
            AppLocalization.localized("common.try_again")
        }

        static var loadingMore: String {
            AppLocalization.localized("common.loading_more")
        }

        static var prompt: String {
            AppLocalization.localized("search.prompt")
        }

        static var searchResultsCount: String {
            AppLocalization.localized("accessibility.search_results_count")
        }

        static var searchNoResults: String {
            AppLocalization.localized("accessibility.search_no_results")
        }

        static var recentSearches: String {
            AppLocalization.localized("search.recent_searches")
        }

        static var trendingTopics: String {
            AppLocalization.localized("search.trending_topics")
        }

        static var recentLabel: String {
            AppLocalization.localized("search.recent_label")
        }

        static var searchHint: String {
            AppLocalization.localized("search.search_hint")
        }

        static var offlineTitle: String {
            AppLocalization.localized("search.offline.title")
        }

        static var offlineMessage: String {
            AppLocalization.localized("search.offline.message")
        }

        static var noResults: String {
            AppLocalization.localized("search.no_results")
        }

        static var sortBy: String {
            AppLocalization.localized("search.sort_by")
        }
    }
}
