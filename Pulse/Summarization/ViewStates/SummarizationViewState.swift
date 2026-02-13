import Foundation

/// View state for the Summarization sheet.
///
/// This state is computed from `SummarizationDomainState` via `SummarizationViewStateReducer`
/// and consumed directly by the SwiftUI view layer.
struct SummarizationViewState: Equatable {
    /// The article being summarized.
    let article: Article

    /// Current state of the summarization process (idle, loading, generating, completed, error).
    var summarizationState: SummarizationState

    /// Accumulated generated summary text (updated token by token during streaming).
    var generatedSummary: String

    /// Current status of the on-device LLM model (notLoaded, loading, ready, error).
    var modelStatus: LLMModelStatus

    /// Creates the initial state for a given article.
    /// - Parameter article: The article to summarize.
    /// - Returns: Initial view state with idle summarization and unloaded model.
    static func initial(article: Article) -> SummarizationViewState {
        SummarizationViewState(
            article: article,
            summarizationState: .idle,
            generatedSummary: "",
            modelStatus: .notLoaded
        )
    }
}
