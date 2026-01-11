import EntropyCore
import Foundation

struct ArticleDetailViewStateReducer: ViewStateReducing {
    func reduce(domainState: ArticleDetailDomainState) -> ArticleDetailViewState {
        ArticleDetailViewState(
            article: domainState.article,
            isProcessingContent: domainState.isProcessingContent,
            processedContent: domainState.processedContent,
            processedDescription: domainState.processedDescription,
            isBookmarked: domainState.isBookmarked,
            showShareSheet: domainState.showShareSheet,
            showSummarizationSheet: domainState.showSummarizationSheet
        )
    }
}
