import Foundation

// MARK: - Summarization State

enum SummarizationState: Equatable {
    case idle
    case loadingModel(progress: Double)
    case generating
    case completed
    case error(String)
}

// MARK: - Domain State

struct SummarizationDomainState: Equatable {
    let article: Article
    var summarizationState: SummarizationState
    var generatedSummary: String
    var modelStatus: LLMModelStatus

    static func initial(article: Article) -> SummarizationDomainState {
        SummarizationDomainState(
            article: article,
            summarizationState: .idle,
            generatedSummary: "",
            modelStatus: .notLoaded
        )
    }
}
