import EntropyCore
import Foundation

struct SummarizationEventActionMap: DomainEventActionMap {
    func map(event: SummarizationViewEvent) -> SummarizationDomainAction? {
        switch event {
        case .onSummarizationStarted:
            return .startSummarization
        case .onSummarizationCancelled:
            return .cancelSummarization
        }
    }
}
