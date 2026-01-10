import Foundation

struct SummarizationViewState: Equatable {
    let article: Article
    var summarizationState: SummarizationState
    var generatedSummary: String
    var modelStatus: LLMModelStatus

    static func initial(article: Article) -> SummarizationViewState {
        SummarizationViewState(
            article: article,
            summarizationState: .idle,
            generatedSummary: "",
            modelStatus: .notLoaded
        )
    }
}
