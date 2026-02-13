import Foundation

// MARK: - Processing Phase

/// Represents the current phase of AI digest generation.
///
/// Used to display appropriate progress indicators and animations
/// during the LLM inference process.
enum AIProcessingPhase: Equatable {
    /// LLM is actively generating digest content token by token.
    case generating

    /// Progress value for UI indicators (always 1.0 for generating phase).
    var progress: Double {
        1.0
    }

    /// Whether the LLM is actively generating (always true).
    var isGenerating: Bool {
        true
    }
}

// MARK: - Display State

/// High-level display state for the Feed view.
///
/// Determines which UI variant to render (loading spinner, content, empty state, etc.).
enum FeedDisplayState: Equatable {
    /// Initial state, no action taken yet.
    case idle

    /// Loading articles from the API.
    case loading

    /// AI is processing and generating the digest.
    case processing(phase: AIProcessingPhase)

    /// Digest generation completed successfully.
    case completed

    /// No articles available to generate digest from.
    case empty

    /// An error occurred during loading or generation.
    case error
}

// MARK: - View State

/// View state for the Feed screen (AI Daily Digest).
///
/// This state is computed from `FeedDomainState` via `FeedViewStateReducer`
/// and consumed directly by the SwiftUI view layer.
struct FeedViewState: Equatable {
    /// Current display state determining which UI variant to show.
    var displayState: FeedDisplayState

    /// Formatted date string for the digest header (e.g., "Monday, January 15").
    var headerDate: String

    /// Accumulated text from streaming token generation.
    var streamingText: String

    /// The completed digest view item, available after generation finishes.
    var digest: DigestViewItem?

    /// Source articles used to generate the digest.
    var sourceArticles: [FeedSourceArticle]

    /// Error message to display, if any.
    var errorMessage: String?

    /// Article selected for navigation to detail view.
    var selectedArticle: Article?

    /// Creates the default initial state with generating phase active.
    static var initial: FeedViewState {
        FeedViewState(
            displayState: .processing(phase: .generating),
            headerDate: "",
            streamingText: "",
            digest: nil,
            sourceArticles: [],
            errorMessage: nil,
            selectedArticle: nil
        )
    }
}

// MARK: - View Items

/// View model for a completed AI-generated digest.
///
/// Contains pre-formatted data optimized for display in the digest card.
struct DigestViewItem: Equatable, Identifiable {
    /// Unique identifier for the digest.
    let id: String

    /// The AI-generated summary text.
    let summary: String

    /// Number of source articles used to generate this digest.
    let articleCount: Int

    /// Formatted timestamp when the digest was generated.
    let generatedAt: String

    /// Creates a view item from a DailyDigest model.
    /// - Parameter digest: The source daily digest.
    init(from digest: DailyDigest) {
        id = digest.id
        summary = digest.summary
        articleCount = digest.articleCount
        generatedAt = digest.formattedDate
    }
}

/// View model for a source article in the Feed.
///
/// Represents an article that was used as a source for the AI digest,
/// displayed in the "Sources" section below the digest content.
struct FeedSourceArticle: Identifiable, Equatable {
    /// Unique identifier for the article.
    let id: String

    /// Article headline/title.
    let title: String

    /// Name of the news source.
    let source: String

    /// Display name of the article's category (e.g., "Technology").
    let category: String?

    /// Category enum value for filtering and styling.
    let categoryType: NewsCategory?

    /// Thumbnail image URL string.
    let imageURL: String?

    /// Original publication date for sorting.
    let publishedAt: Date

    /// Relative formatted date (e.g., "2h ago").
    let formattedDate: String

    /// Reference to the full Article for navigation.
    let article: Article

    /// Creates a source article view item from an Article model.
    /// - Parameter article: The source article.
    init(from article: Article) {
        id = article.id
        title = article.title
        source = article.source.name
        category = article.category?.displayName
        categoryType = article.category
        imageURL = article.displayImageURL
        publishedAt = article.publishedAt
        formattedDate = article.formattedDate
        self.article = article
    }
}

// MARK: - Digest Section

/// Represents a section within the AI-generated digest.
///
/// Used for structured display of digest content with category-based grouping.
struct DigestSection: Identifiable, Equatable {
    /// Unique identifier for the section.
    let id: String

    /// Section title (e.g., "Technology News", "Sports Highlights").
    let title: String

    /// The AI-generated summary content for this section.
    let content: String

    /// Category this section relates to (for styling and filtering).
    let category: NewsCategory?

    /// Source articles relevant to this section.
    let relatedArticles: [FeedSourceArticle]

    /// Whether this section should be visually emphasized as a highlight.
    let isHighlight: Bool

    /// Creates a digest section with the specified properties.
    /// - Parameters:
    ///   - id: Unique identifier (defaults to UUID).
    ///   - title: Section title.
    ///   - content: Summary content.
    ///   - category: Related category (optional).
    ///   - relatedArticles: Source articles for this section.
    ///   - isHighlight: Whether to emphasize this section.
    init(
        id: String = UUID().uuidString,
        title: String,
        content: String,
        category: NewsCategory? = nil,
        relatedArticles: [FeedSourceArticle] = [],
        isHighlight: Bool = false
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.category = category
        self.relatedArticles = relatedArticles
        self.isHighlight = isHighlight
    }
}
