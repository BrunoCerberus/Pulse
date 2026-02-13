import EntropyCore
import Foundation

/// Transforms `SummarizationDomainState` into `SummarizationViewState`.
///
/// This reducer is a pure function that passes through domain state
/// properties for the AI summarization feature. The view state includes
/// the streaming summary text that updates token by token.
///
/// ## Key Properties
/// - `summarizationState`: Controls UI variant (idle, loading, generating, completed, error)
/// - `generatedSummary`: Accumulated text from streaming LLM inference
/// - `modelStatus`: Indicates whether the on-device model is ready
struct SummarizationViewStateReducer: ViewStateReducing {
    /// Reduces domain state to view state.
    /// - Parameter domainState: The current domain state from the interactor.
    /// - Returns: View state ready for consumption by SwiftUI views.
    func reduce(domainState: SummarizationDomainState) -> SummarizationViewState {
        SummarizationViewState(
            article: domainState.article,
            summarizationState: domainState.summarizationState,
            generatedSummary: domainState.generatedSummary,
            modelStatus: domainState.modelStatus
        )
    }
}
