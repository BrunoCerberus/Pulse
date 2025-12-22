import Foundation

struct ForYouDomainState: Equatable {
    var articles: [Article]
    var preferences: UserPreferences
    var isLoading: Bool
    var isLoadingMore: Bool
    var isRefreshing: Bool
    var error: String?
    var currentPage: Int
    var hasMorePages: Bool
    var hasLoadedInitialData: Bool

    static var initial: ForYouDomainState {
        ForYouDomainState(
            articles: [],
            preferences: .default,
            isLoading: false,
            isLoadingMore: false,
            isRefreshing: false,
            error: nil,
            currentPage: 1,
            hasMorePages: true,
            hasLoadedInitialData: false
        )
    }
}
