import Combine
import EntropyCore
import Foundation
import UIKit

/// Domain interactor for the Article Detail feature.
///
/// Manages business logic and state for article viewing, including:
/// - Content processing (HTML stripping, paragraph formatting)
/// - Bookmark management with optimistic updates
/// - Reading history tracking
/// - Share sheet and summarization sheet coordination
///
/// ## Data Flow
/// 1. Views dispatch `ArticleDetailDomainAction` via `dispatch(action:)`
/// 2. Interactor processes actions and updates `ArticleDetailDomainState`
/// 3. State changes are published via `statePublisher`
///
/// ## Dependencies
/// - `StorageService`: Manages bookmarks and reading history
@MainActor
final class ArticleDetailDomainInteractor: CombineInteractor {
    typealias DomainState = ArticleDetailDomainState
    typealias DomainAction = ArticleDetailDomainAction

    private let storageService: StorageService
    private let ttsService: TextToSpeechService?
    private let analyticsService: AnalyticsService?
    private let stateSubject: CurrentValueSubject<ArticleDetailDomainState, Never>
    private var cancellables = Set<AnyCancellable>()
    private var backgroundTasks = Set<Task<Void, Never>>()

    var statePublisher: AnyPublisher<ArticleDetailDomainState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var currentState: ArticleDetailDomainState {
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

        ttsService = try? serviceLocator.retrieve(TextToSpeechService.self)
        analyticsService = try? serviceLocator.retrieve(AnalyticsService.self)

        setupTTSBindings()
        startContentProcessing()
    }

    func dispatch(action: ArticleDetailDomainAction) {
        switch action {
        case .onAppear:
            onAppear()
        case .toggleBookmark:
            toggleBookmark()
        case let .bookmarkStatusLoaded(isBookmarked):
            updateState { $0.isBookmarked = isBookmarked }
        case .showShareSheet:
            analyticsService?.logEvent(.articleShared)
            updateState { $0.showShareSheet = true }
        case .dismissShareSheet:
            updateState { $0.showShareSheet = false }
        case .openInBrowser:
            openInBrowser()
        case let .contentProcessingCompleted(content, description):
            updateState { state in
                state.processedContent = content
                state.processedDescription = description
                state.isProcessingContent = false
            }
        case .showSummarizationSheet:
            updateState { $0.showSummarizationSheet = true }
        case .dismissSummarizationSheet:
            updateState { $0.showSummarizationSheet = false }
        case .startTTS, .toggleTTSPlayback, .stopTTS,
             .cycleTTSSpeed, .ttsPlaybackStateChanged, .ttsProgressUpdated:
            dispatchTTSAction(action)
        }
    }

    // MARK: - Lifecycle

    private func onAppear() {
        analyticsService?.logEvent(.screenView(screen: .articleDetail))
        checkBookmarkStatus()
        markAsRead()
    }

    // MARK: - Reading History

    private func markAsRead() {
        let article = currentState.article
        let task = Task { [weak self] in
            guard let self else { return }
            try? await self.storageService.markArticleAsRead(article)
        }
        trackBackgroundTask(task)
    }

    // MARK: - Bookmark

    private func toggleBookmark() {
        let article = currentState.article
        let wasBookmarked = currentState.isBookmarked

        updateState { $0.isBookmarked = !wasBookmarked }
        analyticsService?.logEvent(wasBookmarked ? .articleUnbookmarked : .articleBookmarked)

        let task = Task { [weak self] in
            guard let self else { return }
            do {
                if wasBookmarked {
                    try await storageService.deleteArticle(article)
                } else {
                    try await storageService.saveArticle(article)
                }
            } catch {
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
        guard let url = URL(string: currentState.article.url),
              let scheme = url.scheme?.lowercased(),
              ["https", "http"].contains(scheme)
        else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Content Processing

    private func startContentProcessing() {
        let article = currentState.article

        let task = Task { [weak self] in
            guard let self else { return }

            let content = await Task.detached(priority: .userInitiated) {
                ArticleDetailTextProcessor.createProcessedContent(from: article.content)
            }.value

            let description = await Task.detached(priority: .userInitiated) {
                ArticleDetailTextProcessor.createProcessedDescription(from: article.description)
            }.value

            guard !Task.isCancelled else { return }

            await MainActor.run { [weak self] in
                self?.dispatch(action: .contentProcessingCompleted(content: content, description: description))
            }
        }
        trackBackgroundTask(task)
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

    private func updateState(_ transform: (inout ArticleDetailDomainState) -> Void) {
        var state = stateSubject.value
        transform(&state)
        stateSubject.send(state)
    }
}

// MARK: - Text-to-Speech

extension ArticleDetailDomainInteractor {
    private func dispatchTTSAction(_ action: ArticleDetailDomainAction) {
        switch action {
        case .startTTS:
            startTTS()
        case .toggleTTSPlayback:
            toggleTTSPlayback()
        case .stopTTS:
            stopTTS()
        case .cycleTTSSpeed:
            cycleTTSSpeed()
        case let .ttsPlaybackStateChanged(state):
            handleTTSPlaybackStateChanged(state)
        case let .ttsProgressUpdated(progress):
            updateState { $0.ttsProgress = progress }
        default:
            break
        }
    }

    private func setupTTSBindings() {
        guard let ttsService else { return }

        ttsService.playbackStatePublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.dispatch(action: .ttsPlaybackStateChanged(state))
            }
            .store(in: &cancellables)

        ttsService.progressPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                self?.dispatch(action: .ttsProgressUpdated(progress))
            }
            .store(in: &cancellables)
    }

    private func startTTS() {
        guard let ttsService else { return }

        let article = currentState.article
        let text = ArticleDetailTextProcessor.buildSpeechText(from: article)
        guard !text.isEmpty else { return }

        let language = AppLocalization.shared.language
        let rate = currentState.ttsSpeedPreset.rate

        ttsService.speak(text: text, language: language, rate: rate)
        updateState { $0.isTTSPlayerVisible = true }
        analyticsService?.logEvent(.ttsStarted)
    }

    private func toggleTTSPlayback() {
        guard let ttsService else { return }

        switch currentState.ttsPlaybackState {
        case .playing:
            ttsService.pause()
        case .paused:
            ttsService.resume()
        case .idle:
            startTTS()
        }
    }

    private func stopTTS() {
        ttsService?.stop()
        updateState { state in
            state.isTTSPlayerVisible = false
            state.ttsProgress = 0.0
        }
        analyticsService?.logEvent(.ttsStopped)
    }

    private func cycleTTSSpeed() {
        let nextPreset = currentState.ttsSpeedPreset.next()
        updateState { $0.ttsSpeedPreset = nextPreset }

        if currentState.ttsPlaybackState == .playing || currentState.ttsPlaybackState == .paused {
            guard let ttsService else { return }
            let article = currentState.article
            let text = ArticleDetailTextProcessor.buildSpeechText(from: article)
            guard !text.isEmpty else { return }

            let language = AppLocalization.shared.language
            ttsService.speak(text: text, language: language, rate: nextPreset.rate)
        }

        analyticsService?.logEvent(.ttsSpeedChanged(speed: nextPreset.label))
    }

    private func handleTTSPlaybackStateChanged(_ state: TTSPlaybackState) {
        updateState { $0.ttsPlaybackState = state }

        if state == .idle, currentState.isTTSPlayerVisible, currentState.ttsProgress >= 1.0 {
            updateState { $0.isTTSPlayerVisible = false }
        }
    }
}
