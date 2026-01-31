import EntropyCore
import Foundation

struct FeedViewStateReducer: ViewStateReducing {
    func reduce(domainState: FeedDomainState) -> FeedViewState {
        let displayState = mapToDisplayState(domainState)
        let digest = domainState.currentDigest.map { DigestViewItem(from: $0) }
        let sourceArticles = domainState.latestArticles.map { FeedSourceArticle(from: $0) }

        let errorMessage: String? = {
            if case let .error(message) = domainState.generationState {
                return message
            }
            return nil
        }()

        return FeedViewState(
            displayState: displayState,
            headerDate: domainState.digestDate,
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
            if domainState.latestArticles.isEmpty && domainState.hasLoadedInitialData {
                return .empty
            }
            return .idle
        case .loadingArticles:
            // Show idle state while fetching articles from API
            // User can see "Generate Digest" button, articles load in background
            return .idle
        case .generating:
            return .processing(phase: .generating)
        case .completed:
            return .completed
        case .error:
            return .error
        }
    }
}
