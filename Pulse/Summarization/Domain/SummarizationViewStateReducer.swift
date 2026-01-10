import Foundation

struct SummarizationViewStateReducer: ViewStateReducing {
    func reduce(domainState: SummarizationDomainState) -> SummarizationViewState {
        SummarizationViewState(
            article: domainState.article,
            summarizationState: domainState.summarizationState,
            generatedSummary: domainState.generatedSummary,
            modelStatus: domainState.modelStatus
        )
    }
}
