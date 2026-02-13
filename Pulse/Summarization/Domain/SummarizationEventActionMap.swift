import EntropyCore
import Foundation

/// Maps view events to domain actions for the Summarization feature.
///
/// This mapper decouples the view layer from domain logic,
/// allowing independent testing of each layer.
///
/// ## Mappings
/// - `onSummarizationStarted` → `startSummarization` (begins LLM inference)
/// - `onSummarizationCancelled` → `cancelSummarization` (stops generation)
struct SummarizationEventActionMap: DomainEventActionMap {
    /// Maps a view event to its corresponding domain action.
    /// - Parameter event: The view event from the UI layer.
    /// - Returns: The domain action to dispatch, or `nil` if no mapping exists.
    func map(event: SummarizationViewEvent) -> SummarizationDomainAction? {
        switch event {
        case .onSummarizationStarted:
            return .startSummarization
        case .onSummarizationCancelled:
            return .cancelSummarization
        }
    }
}
