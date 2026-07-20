import Foundation

/// Domain state for the For You carousel.
///
/// Owned by `ForYouDomainInteractor` and published via `statePublisher`.
/// The carousel is an embedded mini-feature in `HomeView`, so the state is
/// deliberately small — no navigation or sharing flows of its own (those
/// are routed through the host's article-detail mechanism).
struct ForYouDomainState: Equatable {
    /// Top-N scored articles, ordered by score descending. Empty when the
    /// profile hasn't yet accumulated signal or the pool yielded no hits.
    var scoredArticles: [ScoredArticle]

    /// Indicates the initial scoring pass is in progress.
    var isLoading: Bool

    /// Last error message from a scoring failure, if any.
    var error: String?

    static var initial: ForYouDomainState {
        ForYouDomainState(
            scoredArticles: [],
            isLoading: false,
            error: nil,
        )
    }
}
