import Foundation

// MARK: - Feed Generation State

/// Represents the current state of AI digest generation.
///
/// The generation process progresses through these states:
/// `idle` → `loadingArticles` → `generating` → `completed` (or `error`)
enum FeedGenerationState: Equatable {
    /// No generation in progress, ready to start.
    case idle

    /// Loading the latest news articles from the API.
    case loadingArticles

    /// AI model is generating the digest (streaming tokens).
    case generating

    /// Digest generation completed successfully.
    case completed

    /// Generation failed with an error message.
    case error(String)
}

// MARK: - Domain State

/// Represents the domain state for the Feed (AI Daily Digest) feature.
///
/// This state is owned by `FeedDomainInteractor` and published via `statePublisher`.
/// The Feed feature uses on-device LLM (Llama 3.2-1B) to generate personalized
/// daily digests based on the latest news articles from the API.
///
/// - Note: This is a **Premium** feature.
struct FeedDomainState: Equatable {
    /// Current state of the digest generation process.
    var generationState: FeedGenerationState

    /// Latest articles fetched from the API, used as input for digest generation.
    var latestArticles: [Article]

    /// The generated daily digest, if available.
    var currentDigest: DailyDigest?

    /// Text being streamed from the LLM during generation.
    var streamingText: String

    /// Current status of the on-device LLM model.
    var modelStatus: LLMModelStatus

    /// Whether initial data has been loaded at least once.
    var hasLoadedInitialData: Bool

    /// Article selected for navigation to detail view.
    var selectedArticle: Article?

    /// Creates the default initial state.
    /// Starts with `.loadingArticles` to ensure processing animation shows immediately.
    static var initial: FeedDomainState {
        FeedDomainState(
            generationState: .loadingArticles,
            latestArticles: [],
            currentDigest: nil,
            streamingText: "",
            modelStatus: .notLoaded,
            hasLoadedInitialData: false,
            selectedArticle: nil
        )
    }

    var hasArticles: Bool {
        !latestArticles.isEmpty
    }

    var digestDate: String {
        currentDigest?.formattedDate ?? Self.todayFormatter.string(from: Date())
    }

    private static let todayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }()
}
