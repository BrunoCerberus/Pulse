import Combine
import EntropyCore
import Foundation

/// ViewModel for the Reading History screen.
///
/// Implements `CombineViewModel` to transform domain state into view state.
@MainActor
final class ReadingHistoryViewModel: CombineViewModel, ObservableObject {
    typealias ViewState = ReadingHistoryViewState
    typealias ViewEvent = ReadingHistoryViewEvent

    @Published private(set) var viewState: ReadingHistoryViewState = .initial

    private let interactor: ReadingHistoryDomainInteractor

    init(serviceLocator: ServiceLocator) {
        interactor = ReadingHistoryDomainInteractor(serviceLocator: serviceLocator)
        setupBindings()
    }

    func handle(event: ReadingHistoryViewEvent) {
        switch event {
        case .onAppear:
            interactor.dispatch(action: .loadHistory)
        case .onClearHistoryTapped:
            interactor.dispatch(action: .clearHistory)
        case let .onArticleTapped(articleId):
            interactor.dispatch(action: .selectArticle(articleId: articleId))
        case .onArticleNavigated:
            interactor.dispatch(action: .clearSelectedArticle)
        }
    }

    private func setupBindings() {
        interactor.statePublisher
            .map { state in
                ReadingHistoryViewState(
                    articles: state.articles.enumerated().map { index, article in
                        ArticleViewItem(from: article, index: index, isRead: true)
                    },
                    isLoading: state.isLoading,
                    errorMessage: state.error,
                    showEmptyState: !state.isLoading && state.articles.isEmpty,
                    selectedArticle: state.selectedArticle
                )
            }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: &$viewState)
    }
}
