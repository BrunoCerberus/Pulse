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
    private let stateSubject = CurrentValueSubject<DomainState, Never>(.initial)
    private var cancellables = Set<AnyCancellable>()

    var statePublisher: AnyPublisher<DomainState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var currentState: DomainState {
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

        NotificationCenter.default.publisher(for: .cloudSyncDidComplete)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loadBookmarks()
            }
            .store(in: &cancellables)
    }

    func dispatch(action: DomainAction) {
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
        case let .shareArticle(articleId):
            if let article = findArticle(by: articleId) {
                shareArticle(article)
            }
        case .clearArticleToShare:
            clearArticleToShare()
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
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.analyticsService?.recordError(error)
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
        // Preserve existing bookmarks during refresh so users retain access to
        // their saved articles while the fetch is in progress (important for offline UX).
        updateState { state in
            state.isRefreshing = true
            state.error = nil
        }

        bookmarksService.fetchBookmarks()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.analyticsService?.recordError(error)
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
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.analyticsService?.recordError(error)
                    self?.updateState { state in
                        state.error = error.localizedDescription
                    }
                }
            } receiveValue: { [weak self] in
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

    private func shareArticle(_ article: Article) {
        analyticsService?.logEvent(.articleShared)
        updateState { state in
            state.articleToShare = article
        }
    }

    private func clearArticleToShare() {
        updateState { state in
            state.articleToShare = nil
        }
    }

    private func updateState(_ transform: (inout DomainState) -> Void) {
        var state = stateSubject.value
        transform(&state)
        stateSubject.send(state)
    }
}
