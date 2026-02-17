import Combine
import EntropyCore
import Foundation

/// Domain interactor for the Bookmarks feature.
///
/// Manages business logic and state for saved articles, including:
/// - Loading bookmarked articles from local storage
/// - Pull-to-refresh functionality
/// - Removing bookmarks
/// - Article selection
///
/// ## Data Flow
/// 1. Views dispatch `BookmarksDomainAction` via `dispatch(action:)`
/// 2. Interactor processes actions and updates `BookmarksDomainState`
/// 3. State changes are published via `statePublisher`
///
/// ## Dependencies
/// - `BookmarksService`: Fetches and manages bookmarks
@MainActor
final class BookmarksDomainInteractor: CombineInteractor {
    typealias DomainState = BookmarksDomainState
    typealias DomainAction = BookmarksDomainAction

    private let bookmarksService: BookmarksService
    private let analyticsService: AnalyticsService?
    private let stateSubject = CurrentValueSubject<BookmarksDomainState, Never>(.initial)
    private var cancellables = Set<AnyCancellable>()

    var statePublisher: AnyPublisher<BookmarksDomainState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var currentState: BookmarksDomainState {
        stateSubject.value
    }

    init(serviceLocator: ServiceLocator) {
        do {
            bookmarksService = try serviceLocator.retrieve(BookmarksService.self)
        } catch {
            Logger.shared.service("Failed to retrieve BookmarksService: \(error)", level: .warning)
            bookmarksService = LiveBookmarksService(storageService: LiveStorageService())
        }

        analyticsService = try? serviceLocator.retrieve(AnalyticsService.self)
    }

    func dispatch(action: BookmarksDomainAction) {
        switch action {
        case .loadBookmarks:
            loadBookmarks()
        case .refresh:
            refresh()
        case let .removeBookmark(articleId):
            if let article = findArticle(by: articleId) {
                removeBookmark(article)
            }
        case let .selectArticle(articleId):
            if let article = findArticle(by: articleId) {
                selectArticle(article)
            }
        case .clearSelectedArticle:
            clearSelectedArticle()
        }
    }

    private func findArticle(by id: String) -> Article? {
        currentState.bookmarks.first { $0.id == id }
    }

    private func loadBookmarks() {
        analyticsService?.logEvent(.screenView(screen: .bookmarks))

        updateState { state in
            state.isLoading = true
            state.error = nil
        }

        bookmarksService.fetchBookmarks()
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.updateState { state in
                        state.isLoading = false
                        state.error = error.localizedDescription
                    }
                }
            } receiveValue: { [weak self] articles in
                self?.updateState { state in
                    state.bookmarks = articles
                    state.isLoading = false
                }
            }
            .store(in: &cancellables)
    }

    private func refresh() {
        updateState { state in
            state.isRefreshing = true
            state.bookmarks = []
            state.error = nil
        }

        bookmarksService.fetchBookmarks()
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.updateState { state in
                        state.isRefreshing = false
                        state.error = error.localizedDescription
                    }
                }
            } receiveValue: { [weak self] articles in
                self?.updateState { state in
                    state.bookmarks = articles
                    state.isRefreshing = false
                }
            }
            .store(in: &cancellables)
    }

    private func removeBookmark(_ article: Article) {
        bookmarksService.removeBookmark(article)
            .sink { _ in } receiveValue: { [weak self] in
                self?.updateState { state in
                    state.bookmarks.removeAll { $0.id == article.id }
                }
            }
            .store(in: &cancellables)
    }

    private func selectArticle(_ article: Article) {
        analyticsService?.logEvent(.articleOpened(source: .bookmarks))
        updateState { state in
            state.selectedArticle = article
        }
    }

    private func clearSelectedArticle() {
        updateState { state in
            state.selectedArticle = nil
        }
    }

    private func updateState(_ transform: (inout BookmarksDomainState) -> Void) {
        var state = stateSubject.value
        transform(&state)
        stateSubject.send(state)
    }
}
