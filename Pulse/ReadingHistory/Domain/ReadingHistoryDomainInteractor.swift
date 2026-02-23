import Combine
import EntropyCore
import Foundation

/// Domain interactor for the Reading History feature.
///
/// Manages business logic for browsing and clearing the user's reading history.
///
/// ## Dependencies
/// - `StorageService`: Fetches and clears reading history
@MainActor
final class ReadingHistoryDomainInteractor: CombineInteractor {
    typealias DomainState = ReadingHistoryDomainState
    typealias DomainAction = ReadingHistoryDomainAction

    private let storageService: StorageService
    private let stateSubject = CurrentValueSubject<ReadingHistoryDomainState, Never>(.initial)
    private var backgroundTasks = Set<Task<Void, Never>>()

    var statePublisher: AnyPublisher<ReadingHistoryDomainState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var currentState: ReadingHistoryDomainState {
        stateSubject.value
    }

    init(serviceLocator: ServiceLocator) {
        do {
            storageService = try serviceLocator.retrieve(StorageService.self)
        } catch {
            Logger.shared.service("Failed to retrieve StorageService: \(error)", level: .warning)
            storageService = LiveStorageService()
        }
    }

    func dispatch(action: ReadingHistoryDomainAction) {
        switch action {
        case .loadHistory:
            loadHistory()
        case .clearHistory:
            clearHistory()
        case let .selectArticle(articleId):
            if let article = findArticle(by: articleId) {
                selectArticle(article)
            }
        case .clearSelectedArticle:
            clearSelectedArticle()
        }
    }

    private func findArticle(by id: String) -> Article? {
        currentState.articles.first { $0.id == id }
    }

    private func loadHistory() {
        updateState { state in
            state.isLoading = true
            state.error = nil
        }

        let task = Task { [weak self] in
            guard let self else { return }
            do {
                let articles = try await storageService.fetchReadArticles()
                await MainActor.run {
                    self.updateState { state in
                        state.articles = articles
                        state.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.updateState { state in
                        state.isLoading = false
                        state.error = error.localizedDescription
                    }
                }
            }
        }
        trackBackgroundTask(task)
    }

    private func clearHistory() {
        let task = Task { [weak self] in
            guard let self else { return }
            do {
                try await storageService.clearReadingHistory()
                await MainActor.run {
                    self.updateState { state in
                        state.articles = []
                    }
                }
                // Notify Home/Search to clear read indicators
                await MainActor.run {
                    NotificationCenter.default.post(name: .readingHistoryDidClear, object: nil)
                }
            } catch {
                Logger.shared.service("Failed to clear reading history: \(error)", level: .warning)
            }
        }
        trackBackgroundTask(task)
    }

    private func selectArticle(_ article: Article) {
        updateState { state in
            state.selectedArticle = article
        }
    }

    private func clearSelectedArticle() {
        updateState { state in
            state.selectedArticle = nil
        }
    }

    private func updateState(_ transform: (inout ReadingHistoryDomainState) -> Void) {
        var state = stateSubject.value
        transform(&state)
        stateSubject.send(state)
    }

    private func trackBackgroundTask(_ taskToTrack: Task<Void, Never>) {
        backgroundTasks.insert(taskToTrack)

        Task { @MainActor [weak self] in
            _ = await taskToTrack.result
            self?.backgroundTasks.remove(taskToTrack)
        }
    }

    deinit {
        for task in backgroundTasks {
            task.cancel()
        }
    }
}

extension Notification.Name {
    static let readingHistoryDidClear = Notification.Name("readingHistoryDidClear")
}
