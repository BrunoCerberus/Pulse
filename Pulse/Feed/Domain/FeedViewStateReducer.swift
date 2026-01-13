import EntropyCore
import Foundation

struct FeedViewStateReducer: ViewStateReducing {
    func reduce(domainState: FeedDomainState) -> FeedViewState {
        let displayState = mapToDisplayState(domainState)
        let digest = domainState.currentDigest.map { DigestViewItem(from: $0) }
        let sourceArticles = domainState.readingHistory.map { FeedSourceArticle(from: $0) }

        let errorMessage: String? = {
            if case let .error(message) = domainState.generationState {
                return message
            }
            return nil
        }()

        return FeedViewState(
            displayState: displayState,
            headerDate: domainState.digestDate,
            modelLoadingProgress: extractModelProgress(domainState),
            streamingText: domainState.streamingText,
            digest: digest,
            sourceArticles: sourceArticles,
            errorMessage: errorMessage,
            selectedArticle: domainState.selectedArticle
        )
    }

    private func mapToDisplayState(_ domainState: FeedDomainState) -> FeedDisplayState {
        switch domainState.generationState {
        case .idle:
            if domainState.readingHistory.isEmpty && domainState.hasLoadedInitialData {
                return .empty
            }
            return .idle
        case .loadingHistory:
            return .loading
        case let .loadingModel(progress):
            return .loadingModel(progress: progress)
        case .generating:
            return .generating
        case .completed:
            return .completed
        case .error:
            return .error
        }
    }

    private func extractModelProgress(_ domainState: FeedDomainState) -> Double? {
        if case let .loadingModel(progress) = domainState.generationState {
            return progress
        }
        return nil
    }
}
