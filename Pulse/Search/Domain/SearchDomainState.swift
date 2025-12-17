import Foundation

struct SearchDomainState: Equatable {
    var query: String
    var results: [Article]
    var suggestions: [String]
    var isLoading: Bool
    var isLoadingMore: Bool
    var error: String?
    var currentPage: Int
    var hasMorePages: Bool
    var sortBy: SearchSortOption

    static var initial: SearchDomainState {
        SearchDomainState(
            query: "",
            results: [],
            suggestions: [],
            isLoading: false,
            isLoadingMore: false,
            error: nil,
            currentPage: 1,
            hasMorePages: true,
            sortBy: .relevancy
        )
    }
}

enum SearchSortOption: String, CaseIterable, Identifiable {
    case relevancy
    case publishedAt
    case popularity

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .relevancy: return "Relevance"
        case .publishedAt: return "Date"
        case .popularity: return "Popularity"
        }
    }
}
