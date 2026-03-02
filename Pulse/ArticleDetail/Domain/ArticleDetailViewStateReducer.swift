import EntropyCore
import Foundation

/// Transforms `ArticleDetailDomainState` into `ArticleDetailViewState`.
///
/// This reducer is a pure function that passes through most domain state
/// properties directly to the view state. The domain state handles content
/// processing (converting HTML to AttributedString) asynchronously.
///
/// ## Key Transformations
/// - Article and processed content are passed through directly
/// - Bookmark status is reflected from storage
/// - Sheet visibility flags control modal presentation
struct ArticleDetailViewStateReducer: ViewStateReducing {
    /// Reduces domain state to view state.
    /// - Parameter domainState: The current domain state from the interactor.
    /// - Returns: View state ready for consumption by SwiftUI views.
    func reduce(domainState: ArticleDetailDomainState) -> ArticleDetailViewState {
        ArticleDetailViewState(
            article: domainState.article,
            isProcessingContent: domainState.isProcessingContent,
            processedContent: domainState.processedContent,
            processedDescription: domainState.processedDescription,
            isBookmarked: domainState.isBookmarked,
            showShareSheet: domainState.showShareSheet,
            showSummarizationSheet: domainState.showSummarizationSheet,
            ttsPlaybackState: domainState.ttsPlaybackState,
            ttsProgress: domainState.ttsProgress,
            ttsSpeedPreset: domainState.ttsSpeedPreset,
            isTTSPlayerVisible: domainState.isTTSPlayerVisible,
            relatedArticles: domainState.relatedArticles.enumerated().map { index, article in
                ArticleViewItem(from: article, index: index)
            },
            relatedArticleModels: domainState.relatedArticles
        )
    }
}
