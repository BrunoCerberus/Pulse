import Foundation

// MARK: - Summarization State

enum SummarizationState: Equatable {
    case idle
    case loadingModel(progress: Double)
    case generating
    case completed
    case error(String)
}

// MARK: - Article Detail Domain State

struct ArticleDetailDomainState: Equatable {
    let article: Article

    // Content processing
    var isProcessingContent: Bool
    var processedContent: AttributedString?
    var processedDescription: AttributedString?

    // Bookmark state
    var isBookmarked: Bool

    // Share sheet
    var showShareSheet: Bool

    // Summarization (merged from SummarizationViewModel)
    var summarizationState: SummarizationState
    var generatedSummary: String
    var modelStatus: LLMModelStatus
    var showSummarizationSheet: Bool

    static func initial(article: Article) -> ArticleDetailDomainState {
        ArticleDetailDomainState(
            article: article,
            isProcessingContent: true,
            processedContent: nil,
            processedDescription: nil,
            isBookmarked: false,
            showShareSheet: false,
            summarizationState: .idle,
            generatedSummary: "",
            modelStatus: .notLoaded,
            showSummarizationSheet: false
        )
    }
}
