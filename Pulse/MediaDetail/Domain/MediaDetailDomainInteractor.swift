import Combine
import EntropyCore
import Foundation
import UIKit

/// Domain interactor for the Media Detail feature.
///
/// Manages business logic and state for media playback, including:
/// - Playback state coordination (play/pause/seek delegated to view layer)
/// - Bookmark management with optimistic updates
/// - Share sheet and browser coordination
///
/// ## Data Flow
/// 1. Views dispatch `MediaDetailDomainAction` via `dispatch(action:)`
/// 2. Interactor processes actions and updates `MediaDetailDomainState`
/// 3. State changes are published via `statePublisher`
///
/// ## Note
/// Actual playback control (AVPlayer/WKWebView) is handled by the view layer.
/// This interactor only manages state and coordinates UI.
@MainActor
final class MediaDetailDomainInteractor: CombineInteractor {
    typealias DomainState = MediaDetailDomainState
    typealias DomainAction = MediaDetailDomainAction

    private let storageService: StorageService
    private let stateSubject: CurrentValueSubject<MediaDetailDomainState, Never>
    private var cancellables = Set<AnyCancellable>()
    private var backgroundTasks = Set<Task<Void, Never>>()

    var statePublisher: AnyPublisher<MediaDetailDomainState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var currentState: MediaDetailDomainState {
        stateSubject.value
    }

    init(article: Article, serviceLocator: ServiceLocator) {
        stateSubject = CurrentValueSubject(.initial(article: article))

        do {
            storageService = try serviceLocator.retrieve(StorageService.self)
        } catch {
            Logger.shared.service("Failed to retrieve StorageService: \(error)", level: .warning)
            storageService = LiveStorageService()
        }
    }

    func dispatch(action: MediaDetailDomainAction) {
        if handleLifecycle(action) { return }
        if handlePlaybackControl(action) { return }
        if handlePlaybackEvents(action) { return }
        if handleShareSheet(action) { return }
        if handleBookmark(action) { return }
        if handleBrowser(action) { return }
    }

    private func handleLifecycle(_ action: MediaDetailDomainAction) -> Bool {
        switch action {
        case .onAppear:
            onAppear()
            return true
        default:
            return false
        }
    }

    private func handlePlaybackControl(_ action: MediaDetailDomainAction) -> Bool {
        switch action {
        case .play:
            updateState { $0.isPlaying = true }
            return true
        case .pause:
            updateState { $0.isPlaying = false }
            return true
        case let .seek(progress: progress):
            let newTime = currentState.duration * progress
            updateState {
                $0.playbackProgress = progress
                $0.currentTime = newTime
            }
            return true
        case let .skipBackward(seconds):
            let newTime = max(0, currentState.currentTime - seconds)
            updatePlaybackProgress(newTime: newTime)
            return true
        case let .skipForward(seconds):
            let newTime = min(currentState.duration, currentState.currentTime + seconds)
            updatePlaybackProgress(newTime: newTime)
            return true
        default:
            return false
        }
    }

    private func updatePlaybackProgress(newTime: TimeInterval) {
        let progress = currentState.duration > 0 ? newTime / currentState.duration : 0
        updateState {
            $0.currentTime = newTime
            $0.playbackProgress = progress
        }
    }

    private func handlePlaybackEvents(_ action: MediaDetailDomainAction) -> Bool {
        switch action {
        case let .playbackProgressUpdated(progress, currentTime):
            updateState {
                $0.playbackProgress = progress
                $0.currentTime = currentTime
            }
            return true
        case let .durationLoaded(duration):
            updateState {
                $0.duration = duration
                $0.isLoading = false
            }
            return true
        case .playerLoading:
            updateState { $0.isLoading = true }
            return true
        case .playerReady:
            updateState { $0.isLoading = false }
            return true
        case let .playbackError(errorMessage):
            updateState {
                $0.error = errorMessage
                $0.isLoading = false
                $0.isPlaying = false
            }
            return true
        default:
            return false
        }
    }

    private func handleShareSheet(_ action: MediaDetailDomainAction) -> Bool {
        switch action {
        case .showShareSheet:
            updateState { $0.showShareSheet = true }
            return true
        case .dismissShareSheet:
            updateState { $0.showShareSheet = false }
            return true
        default:
            return false
        }
    }

    private func handleBookmark(_ action: MediaDetailDomainAction) -> Bool {
        switch action {
        case .toggleBookmark:
            toggleBookmark()
            return true
        case let .bookmarkStatusLoaded(isBookmarked):
            updateState { $0.isBookmarked = isBookmarked }
            return true
        default:
            return false
        }
    }

    private func handleBrowser(_ action: MediaDetailDomainAction) -> Bool {
        switch action {
        case .openInBrowser:
            openInBrowser()
            return true
        default:
            return false
        }
    }

    // MARK: - Lifecycle

    private func onAppear() {
        checkBookmarkStatus()
    }

    // MARK: - Bookmark

    private func toggleBookmark() {
        let article = currentState.article
        let wasBookmarked = currentState.isBookmarked

        // Optimistic update
        updateState { $0.isBookmarked = !wasBookmarked }

        let task = Task { [weak self] in
            guard let self else { return }
            do {
                if wasBookmarked {
                    try await storageService.deleteArticle(article)
                } else {
                    try await storageService.saveArticle(article)
                }
            } catch {
                // Revert on error
                await MainActor.run { [weak self] in
                    self?.updateState { $0.isBookmarked = wasBookmarked }
                }
            }
        }
        trackBackgroundTask(task)
    }

    private func checkBookmarkStatus() {
        let articleId = currentState.article.id
        let task = Task { [weak self] in
            guard let self else { return }
            let isBookmarked = await storageService.isBookmarked(articleId)
            await MainActor.run { [weak self] in
                self?.dispatch(action: .bookmarkStatusLoaded(isBookmarked))
            }
        }
        trackBackgroundTask(task)
    }

    // MARK: - Browser

    private func openInBrowser() {
        guard let url = URL(string: currentState.article.url) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Background Task Management

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

    private func updateState(_ transform: (inout MediaDetailDomainState) -> Void) {
        var state = stateSubject.value
        transform(&state)
        stateSubject.send(state)
    }
}
