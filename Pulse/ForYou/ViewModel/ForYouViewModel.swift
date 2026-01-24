import Combine
import EntropyCore
import Foundation

/// ViewModel for the For You (personalized feed) screen.
///
/// Implements `CombineViewModel` to transform domain state into view state.
/// Provides personalized articles based on the user's followed topics.
///
/// ## Features
/// - Personalized feed based on preferences
/// - Infinite scroll with pagination
/// - Topic onboarding when no topics are followed
///
/// - Note: This is a **Premium** feature.
@MainActor
final class ForYouViewModel: CombineViewModel, ObservableObject {
    typealias ViewState = ForYouViewState
    typealias ViewEvent = ForYouViewEvent

    @Published private(set) var viewState: ForYouViewState = .initial

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
        case let .onArticleTapped(articleId):
            interactor.dispatch(action: .selectArticle(articleId: articleId))
        case .onArticleNavigated:
            interactor.dispatch(action: .clearSelectedArticle)
        }
    }

    private func setupBindings() {
        interactor.statePublisher
            .map { state in
                ForYouViewState(
                    articles: state.articles.enumerated().map { index, article in
                        ArticleViewItem(from: article, index: index)
                    },
                    followedTopics: state.preferences.followedTopics,
                    isLoading: state.isLoading,
                    isLoadingMore: state.isLoadingMore,
                    isRefreshing: state.isRefreshing,
                    errorMessage: state.error,
                    showEmptyState: !state.isLoading && !state.isRefreshing && state.articles.isEmpty,
                    showOnboarding: state.preferences.followedTopics.isEmpty && !state.isLoading && !state.isRefreshing,
                    selectedArticle: state.selectedArticle
                )
            }
            .removeDuplicates()
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
    var selectedArticle: Article?

    static var initial: ForYouViewState {
        ForYouViewState(
            articles: [],
            followedTopics: [],
            isLoading: false,
            isLoadingMore: false,
            isRefreshing: false,
            errorMessage: nil,
            showEmptyState: false,
            showOnboarding: false,
            selectedArticle: nil
        )
    }
}

enum ForYouViewEvent: Equatable {
    case onAppear
    case onRefresh
    case onLoadMore
    case onArticleTapped(articleId: String)
    case onArticleNavigated
}
