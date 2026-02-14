import EntropyCore
import Foundation

/// Transforms `FeedDomainState` into `FeedViewState`.
///
/// This reducer is a pure function that:
/// - Maps generation state to display state for UI variants
/// - Converts DailyDigest to DigestViewItem
/// - Extracts error messages from generation state
/// - Formats streaming text for display
///
/// ## Display State Mapping
/// - `idle` → `.idle` or `.empty` (if no articles after initial load)
/// - `loadingArticles` → `.processing(phase: .generating)`
/// - `generating` → `.processing(phase: .generating)`
/// - `completed` → `.completed`
/// - `error` → `.error`
struct FeedViewStateReducer: ViewStateReducing {
    /// Reduces domain state to view state.
    /// - Parameter domainState: The current domain state from the interactor.
    /// - Returns: View state ready for consumption by SwiftUI views.
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
            selectedArticle: domainState.selectedArticle,
            isOfflineError: domainState.isOfflineError
        )
    }

    /// Maps the domain generation state to a display state for the UI.
    ///
    /// Handles the nuanced mapping where `loadingArticles` shows the generating animation
    /// because digest generation starts automatically after articles load.
    ///
    /// - Parameter domainState: The current domain state.
    /// - Returns: The appropriate display state for the view.
    private func mapToDisplayState(_ domainState: FeedDomainState) -> FeedDisplayState {
        switch domainState.generationState {
        case .idle:
            if domainState.latestArticles.isEmpty && domainState.hasLoadedInitialData {
                return .empty
            }
            return .idle
        case .loadingArticles:
            // Show processing animation while fetching articles
            // Digest generation starts automatically after articles load
            return .processing(phase: .generating)
        case .generating:
            return .processing(phase: .generating)
        case .completed:
            return .completed
        case .error:
            return .error
        }
    }
}
