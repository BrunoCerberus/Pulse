import Combine
import EntropyCore
import Foundation

/// ViewModel for the Bookmarks screen.
///
/// Implements `CombineViewModel` to transform domain state into view state.
/// Manages the list of user's bookmarked articles with pull-to-refresh support.
///
/// ## Features
/// - Load bookmarked articles from local storage
/// - Pull-to-refresh functionality
/// - Remove bookmarks via swipe action
@MainActor
final class BookmarksViewModel: CombineViewModel, ObservableObject {
    typealias ViewState = BookmarksViewState
    typealias ViewEvent = BookmarksViewEvent

    @Published private(set) var viewState: BookmarksViewState = .initial

    private let interactor: BookmarksDomainInteractor

    init(serviceLocator: ServiceLocator) {
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
        case let .onShareTapped(articleId):
            interactor.dispatch(action: .shareArticle(articleId: articleId))
        case .onShareDismissed:
            interactor.dispatch(action: .clearArticleToShare)
        }
    }

    private func setupBindings() {
        interactor.statePublisher
            .map { state in
                BookmarksViewState(
                    bookmarks: state.bookmarks.enumerated().map { index, article in
                        ArticleViewItem(from: article, index: index)
                    },
                    isLoading: state.isLoading,
                    isRefreshing: state.isRefreshing,
                    errorMessage: state.error,
                    showEmptyState: !state.isLoading && !state.isRefreshing && state.bookmarks.isEmpty,
                    selectedArticle: state.selectedArticle,
                    articleToShare: state.articleToShare
                )
            }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: &$viewState)
    }
}

/// View state for the Bookmarks screen.
///
/// Contains the user's saved articles and UI state for loading,
/// refreshing, and navigation.
struct BookmarksViewState: Equatable {
    /// Bookmarked articles as view items for display.
    var bookmarks: [ArticleViewItem]

    /// Indicates whether bookmarks are being loaded from storage.
    var isLoading: Bool

    /// Indicates whether a pull-to-refresh operation is in progress.
    var isRefreshing: Bool

    /// Error message to display, if any.
    var errorMessage: String?

    /// Whether to show the empty state view (no bookmarks saved).
    var showEmptyState: Bool

    /// Article selected for navigation to detail view.
    var selectedArticle: Article?

    /// Article selected for sharing via the system share sheet.
    var articleToShare: Article?

    /// Creates the default initial state with empty bookmarks.
    static var initial: BookmarksViewState {
        BookmarksViewState(
            bookmarks: [],
            isLoading: false,
            isRefreshing: false,
            errorMessage: nil,
            showEmptyState: false,
            selectedArticle: nil,
            articleToShare: nil
        )
    }
}

/// Events that can be triggered from the Bookmarks view.
///
/// These events are handled by the `BookmarksViewModel` and mapped
/// to domain actions via the interactor.
enum BookmarksViewEvent: Equatable {
    /// View appeared, should load bookmarks.
    case onAppear

    /// User initiated pull-to-refresh.
    case onRefresh

    /// User tapped on a bookmarked article.
    /// - Parameter articleId: The unique identifier of the tapped article.
    case onArticleTapped(articleId: String)

    /// Navigation to article detail completed.
    case onArticleNavigated

    /// User requested to remove a bookmark (swipe action).
    /// - Parameter articleId: The unique identifier of the article to unbookmark.
    case onRemoveBookmark(articleId: String)

    /// User tapped share on a bookmarked article.
    case onShareTapped(articleId: String)

    /// Share sheet was dismissed.
    case onShareDismissed
}
