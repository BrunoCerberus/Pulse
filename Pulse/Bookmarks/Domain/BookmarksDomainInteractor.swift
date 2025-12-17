import Foundation
import Combine

final class BookmarksDomainInteractor: CombineInteractor {
    typealias DomainState = BookmarksDomainState
    typealias DomainAction = BookmarksDomainAction

    private let bookmarksService: BookmarksService
    private let storageService: StorageService
    private let stateSubject = CurrentValueSubject<BookmarksDomainState, Never>(.initial)
    private var cancellables = Set<AnyCancellable>()

    var statePublisher: AnyPublisher<BookmarksDomainState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var currentState: BookmarksDomainState {
        stateSubject.value
    }

    init(
        bookmarksService: BookmarksService = ServiceLocator.shared.resolve(BookmarksService.self),
        storageService: StorageService = ServiceLocator.shared.resolve(StorageService.self)
    ) {
        self.bookmarksService = bookmarksService
        self.storageService = storageService
    }

    func dispatch(action: BookmarksDomainAction) {
        switch action {
        case .loadBookmarks:
            loadBookmarks()
        case let .removeBookmark(article):
            removeBookmark(article)
        case let .selectArticle(article):
            saveToReadingHistory(article)
        }
    }

    private func loadBookmarks() {
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

    private func removeBookmark(_ article: Article) {
        bookmarksService.removeBookmark(article)
            .sink { _ in } receiveValue: { [weak self] in
                self?.updateState { state in
                    state.bookmarks.removeAll { $0.id == article.id }
                }
            }
            .store(in: &cancellables)
    }

    private func saveToReadingHistory(_ article: Article) {
        Task {
            try? await storageService.saveReadingHistory(article)
        }
    }

    private func updateState(_ transform: (inout BookmarksDomainState) -> Void) {
        var state = stateSubject.value
        transform(&state)
        stateSubject.send(state)
    }
}
