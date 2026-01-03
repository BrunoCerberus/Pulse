import Combine
import Foundation

final class BookmarksDomainInteractor: CombineInteractor {
    typealias DomainState = BookmarksDomainState
    typealias DomainAction = BookmarksDomainAction

    private let bookmarksService: BookmarksService
    private let storageService: StorageService
    private let stateSubject = CurrentValueSubject<BookmarksDomainState, Never>(.initial)
    private var cancellables = Set<AnyCancellable>()
    private var backgroundTasks = Set<Task<Void, Never>>()

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

        do {
            storageService = try serviceLocator.retrieve(StorageService.self)
        } catch {
            Logger.shared.service("Failed to retrieve StorageService: \(error)", level: .warning)
            storageService = LiveStorageService()
        }
    }

    func dispatch(action: BookmarksDomainAction) {
        switch action {
        case .loadBookmarks:
            loadBookmarks()
        case .refresh:
            refresh()
        case let .removeBookmark(article):
            removeBookmark(article)
        case let .selectArticle(article):
            selectArticle(article)
        case .clearSelectedArticle:
            clearSelectedArticle()
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
        updateState { state in
            state.selectedArticle = article
        }
        saveToReadingHistory(article)
    }

    private func clearSelectedArticle() {
        updateState { state in
            state.selectedArticle = nil
        }
    }

    private func saveToReadingHistory(_ article: Article) {
        let task = Task { [weak self] in
            guard let self else { return }
            try? await storageService.saveReadingHistory(article)
        }
        backgroundTasks.insert(task)
        Task {
            await task.value
            backgroundTasks.remove(task)
        }
    }

    deinit {
        backgroundTasks.forEach { $0.cancel() }
    }

    private func updateState(_ transform: (inout BookmarksDomainState) -> Void) {
        var state = stateSubject.value
        transform(&state)
        stateSubject.send(state)
    }
}
