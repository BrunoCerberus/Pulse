import Combine
import Foundation

final class BookmarksViewModel: CombineViewModel, ObservableObject {
    typealias ViewState = BookmarksViewState
    typealias ViewEvent = BookmarksViewEvent

    @Published private(set) var viewState: BookmarksViewState = .initial
    @Published var selectedArticle: Article?

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
        case let .onArticleTapped(article):
            selectedArticle = article
            interactor.dispatch(action: .selectArticle(article))
        case let .onRemoveBookmark(article):
            interactor.dispatch(action: .removeBookmark(article))
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
                    showEmptyState: !state.isLoading && !state.isRefreshing && state.bookmarks.isEmpty
                )
            }
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

    static var initial: BookmarksViewState {
        BookmarksViewState(
            bookmarks: [],
            isLoading: false,
            isRefreshing: false,
            errorMessage: nil,
            showEmptyState: false
        )
    }
}

enum BookmarksViewEvent: Equatable {
    case onAppear
    case onRefresh
    case onArticleTapped(Article)
    case onRemoveBookmark(Article)
}
