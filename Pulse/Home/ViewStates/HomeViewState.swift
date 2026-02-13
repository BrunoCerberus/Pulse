import Foundation

/// View state for the Home screen.
///
/// This state is computed from `HomeDomainState` via `HomeViewStateReducer`
/// and consumed directly by the SwiftUI view layer.
struct HomeViewState: Equatable {
    /// Breaking news articles displayed in the hero carousel.
    var breakingNews: [ArticleViewItem]

    /// Regular headlines displayed in the main article list with infinite scroll.
    var headlines: [ArticleViewItem]

    /// Indicates whether initial data is being loaded.
    var isLoading: Bool

    /// Indicates whether additional pages are being loaded (infinite scroll).
    var isLoadingMore: Bool

    /// Indicates whether a pull-to-refresh operation is in progress.
    var isRefreshing: Bool

    /// Error message to display, if any.
    var errorMessage: String?

    /// Whether to show the empty state view (no articles available).
    var showEmptyState: Bool

    /// Article selected for navigation to detail view.
    var selectedArticle: Article?

    /// Article selected for sharing via share sheet.
    var articleToShare: Article?

    /// Currently selected category filter (nil = all categories).
    var selectedCategory: NewsCategory?

    /// Categories the user has chosen to follow for personalized content.
    var followedTopics: [NewsCategory]

    /// Whether to display category filter tabs (requires followed topics).
    var showCategoryTabs: Bool

    /// All available news categories for topic selection.
    var allTopics: [NewsCategory]

    /// Whether the user is currently editing their followed topics.
    var isEditingTopics: Bool

    /// Creates the default initial state with empty data and loading flags disabled.
    static var initial: HomeViewState {
        HomeViewState(
            breakingNews: [],
            headlines: [],
            isLoading: false,
            isLoadingMore: false,
            isRefreshing: false,
            errorMessage: nil,
            showEmptyState: false,
            selectedArticle: nil,
            articleToShare: nil,
            selectedCategory: nil,
            followedTopics: [],
            showCategoryTabs: false,
            allTopics: NewsCategory.allCases,
            isEditingTopics: false
        )
    }
}

/// View model for a single article item.
///
/// Contains pre-formatted data optimized for display in the view layer,
/// avoiding heavy computation in SwiftUI view bodies.
struct ArticleViewItem: Identifiable, Equatable {
    /// Unique identifier for the article.
    let id: String

    /// Article headline/title.
    let title: String

    /// Brief description or excerpt of the article content.
    let description: String?

    /// Name of the news source (e.g., "The Guardian", "BBC News").
    let sourceName: String

    /// Thumbnail image URL for list cells (prefers smaller/thumbnail URL).
    let imageURL: URL?

    /// High-resolution image URL for carousel/featured display (prefers full-size URL).
    let heroImageURL: URL?

    /// Relative formatted date (e.g., "2h ago", "Yesterday").
    let formattedDate: String

    /// News category for filtering and display.
    let category: NewsCategory?

    /// Pre-computed index for staggered animations (avoids re-enumeration in view body).
    let animationIndex: Int

    /// Creates a view item from an Article model.
    /// - Parameters:
    ///   - article: The source article.
    ///   - index: Index for staggered animation delay calculation.
    init(from article: Article, index: Int = 0) {
        id = article.id
        title = article.title
        description = article.description
        sourceName = article.source.name
        imageURL = article.displayImageURL.flatMap { URL(string: $0) }
        heroImageURL = article.heroImageURL.flatMap { URL(string: $0) }
        formattedDate = article.formattedDate
        category = article.category
        animationIndex = index
    }
}
