import Combine
import EntropyCore
import Foundation

@MainActor
final class BookmarksViewModel: CombineViewModel, ObservableObject {
    typealias ViewState = BookmarksViewState
    typealias ViewEvent = BookmarksViewEvent

    @Published private(set) var viewState: BookmarksViewState = .initial

    private let serviceLocator: ServiceLocator
    private let interactor: BookmarksDomainInteractor
    private var cancellables = Set<AnyCancellable>()

    init(serviceLocator: ServiceLocator) {
        self.serviceLocator = serviceLocator
        interactor = BookmarksDomainInteractor(serviceLocator: serviceLocator)
        setupBindings()
    }

    func handle(event: BookmarksViewEvent) {
        switch event {
        case .onAppear:
            interactor.dispatch(action: .loadBookmarks)
        case .onRefresh:
            interactor.dispatch(action: .refresh)
        case let .onArticleTapped(articleId):
            interactor.dispatch(action: .selectArticle(articleId: articleId))
        case .onArticleNavigated:
            interactor.dispatch(action: .clearSelectedArticle)
        case let .onRemoveBookmark(articleId):
            interactor.dispatch(action: .removeBookmark(articleId: articleId))
        }
    }

    private func setupBindings() {
        interactor.statePublisher
            .map { state in
                BookmarksViewState(
                    bookmarks: state.bookmarks.map { ArticleViewItem(from: $0) },
                    isLoading: state.isLoading,
                    isRefreshing: state.isRefreshing,
                    errorMessage: state.error,
                    showEmptyState: !state.isLoading && !state.isRefreshing && state.bookmarks.isEmpty,
                    selectedArticle: state.selectedArticle
                )
            }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: &$viewState)
    }
}

struct BookmarksViewState: Equatable {
    var bookmarks: [ArticleViewItem]
    var isLoading: Bool
    var isRefreshing: Bool
    var errorMessage: String?
    var showEmptyState: Bool
    var selectedArticle: Article?

    static var initial: BookmarksViewState {
        BookmarksViewState(
            bookmarks: [],
            isLoading: false,
            isRefreshing: false,
            errorMessage: nil,
            showEmptyState: false,
            selectedArticle: nil
        )
    }
}

enum BookmarksViewEvent: Equatable {
    case onAppear
    case onRefresh
    case onArticleTapped(articleId: String)
    case onArticleNavigated
    case onRemoveBookmark(articleId: String)
}
