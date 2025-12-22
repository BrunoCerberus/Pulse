import Combine
import Foundation

final class ForYouViewModel: CombineViewModel, ObservableObject {
    typealias ViewState = ForYouViewState
    typealias ViewEvent = ForYouViewEvent

    @Published private(set) var viewState: ForYouViewState = .initial
    @Published var selectedArticle: Article?

    private let serviceLocator: ServiceLocator
    private let interactor: ForYouDomainInteractor
    private var cancellables = Set<AnyCancellable>()

    init(serviceLocator: ServiceLocator) {
        self.serviceLocator = serviceLocator
        interactor = ForYouDomainInteractor(serviceLocator: serviceLocator)
        setupBindings()
    }

    func handle(event: ForYouViewEvent) {
        switch event {
        case .onAppear:
            interactor.dispatch(action: .loadFeed)
        case .onRefresh:
            interactor.dispatch(action: .refresh)
        case .onLoadMore:
            interactor.dispatch(action: .loadMore)
        case let .onArticleTapped(article):
            selectedArticle = article
            interactor.dispatch(action: .selectArticle(article))
        }
    }

    private func setupBindings() {
        interactor.statePublisher
            .map { state in
                ForYouViewState(
                    articles: state.articles.map { ArticleViewItem(from: $0) },
                    followedTopics: state.preferences.followedTopics,
                    isLoading: state.isLoading,
                    isLoadingMore: state.isLoadingMore,
                    isRefreshing: state.isRefreshing,
                    errorMessage: state.error,
                    showEmptyState: !state.isLoading && !state.isRefreshing && state.articles.isEmpty,
                    showOnboarding: state.preferences.followedTopics.isEmpty && !state.isLoading && !state.isRefreshing
                )
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$viewState)
    }
}

struct ForYouViewState: Equatable {
    var articles: [ArticleViewItem]
    var followedTopics: [NewsCategory]
    var isLoading: Bool
    var isLoadingMore: Bool
    var isRefreshing: Bool
    var errorMessage: String?
    var showEmptyState: Bool
    var showOnboarding: Bool

    static var initial: ForYouViewState {
        ForYouViewState(
            articles: [],
            followedTopics: [],
            isLoading: false,
            isLoadingMore: false,
            isRefreshing: false,
            errorMessage: nil,
            showEmptyState: false,
            showOnboarding: false
        )
    }
}

enum ForYouViewEvent: Equatable {
    case onAppear
    case onRefresh
    case onLoadMore
    case onArticleTapped(Article)
}
