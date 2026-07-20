import Combine
import EntropyCore
import Foundation

/// ViewModel for the embedded For You carousel.
///
/// Mirrors the simpler `BookmarksViewModel` pattern (no separate Reducer /
/// EventActionMap files) — the carousel is a small mini-feature, not a
/// full screen, so the inline event-to-action mapping is enough.
///
/// ## Composition
/// `HomeView` instantiates one `ForYouViewModel`, passes new article
/// pools via `.onPoolChanged`, and renders `viewState.cards` only when
/// `viewState.isVisible` is true.
@MainActor
final class ForYouViewModel: CombineViewModel, ObservableObject {
    typealias ViewState = ForYouViewState
    typealias ViewEvent = ForYouViewEvent

    @Published private(set) var viewState: ForYouViewState = .initial

    private let interactor: ForYouDomainInteractor
    private let forYouService: ForYouService?

    init(serviceLocator: ServiceLocator) {
        interactor = ForYouDomainInteractor(serviceLocator: serviceLocator)
        forYouService = try? serviceLocator.retrieve(ForYouService.self)
        setupBindings()
    }

    func handle(event: ForYouViewEvent) {
        switch event {
        case let .onPoolChanged(pool):
            interactor.dispatch(action: .scoreFromPool(pool: pool))
        }
    }

    private func setupBindings() {
        let service = forYouService
        interactor.statePublisher
            .map { state in
                let cards = state.scoredArticles.enumerated().map { index, scored in
                    ForYouCardItem(
                        from: scored,
                        index: index,
                        explanation: service?.explanation(for: scored.matchedTopics) ?? "",
                    )
                }
                return ForYouViewState(
                    cards: cards,
                    isLoading: state.isLoading,
                    // Hide the section when there's nothing to show and
                    // we're not actively loading — keeps Home uncluttered
                    // for cold-start users with no profile signal yet.
                    isVisible: state.isLoading || !cards.isEmpty,
                    errorMessage: state.error,
                )
            }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: &$viewState)
    }
}

// MARK: - View State

/// View state for the For You carousel.
struct ForYouViewState: Equatable {
    var cards: [ForYouCardItem]
    var isLoading: Bool
    /// `true` when we either have cards to show or are loading. Hiding
    /// when both are false keeps Home uncluttered for cold-start users.
    var isVisible: Bool
    var errorMessage: String?

    static var initial: ForYouViewState {
        ForYouViewState(cards: [], isLoading: false, isVisible: false, errorMessage: nil)
    }
}

/// View item for a single For You card.
struct ForYouCardItem: Identifiable, Equatable {
    let id: String
    let articleViewItem: ArticleViewItem
    let score: Double
    let matchedTopics: [String]
    /// Pre-computed "Why this?" explanation, e.g. `"Technology, Science"`.
    let explanation: String
    let animationIndex: Int

    init(from scored: ScoredArticle, index: Int, explanation: String) {
        id = scored.article.id
        articleViewItem = ArticleViewItem(from: scored.article, index: index, isRead: false)
        score = scored.score
        matchedTopics = scored.matchedTopics
        self.explanation = explanation
        animationIndex = index
    }
}

// MARK: - View Event

enum ForYouViewEvent: Equatable {
    /// The host's article pool changed — re-score against the new pool.
    case onPoolChanged([Article])
}
