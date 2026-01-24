import Foundation

// MARK: - Feed Generation State

/// Represents the current state of AI digest generation.
///
/// The generation process progresses through these states:
/// `idle` → `loadingHistory` → `generating` → `completed` (or `error`)
enum FeedGenerationState: Equatable {
    /// No generation in progress, ready to start.
    case idle

    /// Loading the user's recent reading history.
    case loadingHistory

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
/// daily digests based on the user's reading history.
///
/// - Note: This is a **Premium** feature.
struct FeedDomainState: Equatable {
    /// Current state of the digest generation process.
    var generationState: FeedGenerationState

    /// Articles read in the last 48 hours, used as input for digest generation.
    var readingHistory: [Article]

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
    static var initial: FeedDomainState {
        FeedDomainState(
            generationState: .idle,
            readingHistory: [],
            currentDigest: nil,
            streamingText: "",
            modelStatus: .notLoaded,
            hasLoadedInitialData: false,
            selectedArticle: nil
        )
    }

    var hasRecentReadingHistory: Bool {
        !readingHistory.isEmpty
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
