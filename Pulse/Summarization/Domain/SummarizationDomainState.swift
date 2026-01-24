import Foundation

// MARK: - Summarization State

/// Represents the current state of article summarization.
///
/// The summarization process progresses through these states:
/// `idle` → `loadingModel` → `generating` → `completed` (or `error`)
enum SummarizationState: Equatable {
    /// No summarization in progress, ready to start.
    case idle

    /// On-device LLM model is being loaded.
    /// - Parameter progress: Loading progress from 0.0 to 1.0.
    case loadingModel(progress: Double)

    /// Model is generating the summary (streaming tokens).
    case generating

    /// Summary generation completed successfully.
    case completed

    /// Summarization failed with an error message.
    case error(String)
}

// MARK: - Domain State

/// Represents the domain state for the Article Summarization feature.
///
/// This state is owned by `SummarizationDomainInteractor` and published via `statePublisher`.
/// The feature uses on-device LLM (Llama 3.2-1B) to generate article summaries.
///
/// - Note: This is a **Premium** feature.
struct SummarizationDomainState: Equatable {
    /// The article being summarized.
    let article: Article

    /// Current state of the summarization process.
    var summarizationState: SummarizationState

    /// The generated summary text (accumulates as tokens stream in).
    var generatedSummary: String

    /// Current status of the on-device LLM model.
    var modelStatus: LLMModelStatus

    /// Creates the initial state for a given article.
    /// - Parameter article: The article to summarize.
    /// - Returns: Initial state ready to begin summarization.
    static func initial(article: Article) -> SummarizationDomainState {
        SummarizationDomainState(
            article: article,
            summarizationState: .idle,
            generatedSummary: "",
            modelStatus: .notLoaded
        )
    }
}
