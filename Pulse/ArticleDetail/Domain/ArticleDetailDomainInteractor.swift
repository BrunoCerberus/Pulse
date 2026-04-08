// swiftlint:disable file_length
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
// swiftlint:disable:next type_body_length
final class ArticleDetailDomainInteractor: CombineInteractor {
    typealias DomainState = ArticleDetailDomainState
    typealias DomainAction = ArticleDetailDomainAction

    private let storageService: StorageService
    private let newsService: NewsService?
    private let ttsService: TextToSpeechService?
    private let analyticsService: AnalyticsService?
    private let stateSubject: CurrentValueSubject<DomainState, Never>
    private var cancellables = Set<AnyCancellable>()
    private var ttsCancellables = Set<AnyCancellable>()
    private var backgroundTasks = Set<Task<Void, Never>>()

    /// Monotonically increasing counter that invalidates stale TTS callbacks.
    /// Incremented on every speed-change restart; callbacks from previous generations are discarded.
    private var ttsGeneration = 0

    var statePublisher: AnyPublisher<DomainState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var currentState: DomainState {
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

        newsService = try? serviceLocator.retrieve(NewsService.self)
        ttsService = try? serviceLocator.retrieve(TextToSpeechService.self)
        analyticsService = try? serviceLocator.retrieve(AnalyticsService.self)

        setupTTSBindings()

        // Start content processing immediately on init
        startContentProcessing()
    }

    // swiftlint:disable:next cyclomatic_complexity
    func dispatch(action: DomainAction) {
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

        // MARK: - TTS Actions
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

        // MARK: - Related Articles Actions
        case let .relatedArticlesLoaded(articles):
            updateState { state in
                state.relatedArticles = articles
                state.isLoadingRelatedArticles = false
            }
        }
    }

    // MARK: - Lifecycle

    private func onAppear() {
        analyticsService?.logEvent(.screenView(screen: .articleDetail))
        checkBookmarkStatus()
        markAsRead()
        loadRelatedArticles()
    }

    // MARK: - Reading History

    private func markAsRead() {
        let article = currentState.article
        let service = UncheckedSendableBox(value: storageService)
        let task = Task { [weak self] in
            guard self != nil else { return }
            try? await service.value.markArticleAsRead(article)
        }
        trackBackgroundTask(task)
    }

    // MARK: - Bookmark

    private func toggleBookmark() {
        let article = currentState.article
        let wasBookmarked = currentState.isBookmarked

        // Optimistic update
        updateState { $0.isBookmarked = !wasBookmarked }
        analyticsService?.logEvent(wasBookmarked ? .articleUnbookmarked : .articleBookmarked)

        let service = UncheckedSendableBox(value: storageService)
        let task = Task { [weak self] in
            guard let self else { return }
            do {
                if wasBookmarked {
                    try await service.value.deleteArticle(article)
                } else {
                    try await service.value.saveArticle(article)
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
        let service = UncheckedSendableBox(value: storageService)
        let task = Task { [weak self] in
            guard let self else { return }
            let isBookmarked = await service.value.isBookmarked(articleId)
            await MainActor.run { [weak self] in
                self?.dispatch(action: .bookmarkStatusLoaded(isBookmarked))
            }
        }
        trackBackgroundTask(task)
    }

    // MARK: - Related Articles

    private func loadRelatedArticles() {
        guard let newsService, let category = currentState.article.category else { return }

        updateState { $0.isLoadingRelatedArticles = true }

        let currentArticleId = currentState.article.id
        let language = AppLocalization.shared.language

        newsService.fetchTopHeadlines(category: category, language: language, country: "us", page: 1)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure = completion {
                        self?.updateState { $0.isLoadingRelatedArticles = false }
                    }
                },
                receiveValue: { [weak self] articles in
                    let related = Array(
                        articles
                            .filter { $0.id != currentArticleId && !$0.isMedia }
                            .prefix(5)
                    )
                    self?.dispatch(action: .relatedArticlesLoaded(related))
                }
            )
            .store(in: &cancellables)
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
                self.createProcessedContent(from: article.content)
            }.value

            let description = await Task.detached(priority: .userInitiated) {
                self.createProcessedDescription(from: article.description)
            }.value

            guard !Task.isCancelled else { return }

            await MainActor.run { [weak self] in
                self?.dispatch(action: .contentProcessingCompleted(content: content, description: description))
            }
        }
        trackBackgroundTask(task)
    }

    private nonisolated func createProcessedContent(from content: String?) -> AttributedString? {
        guard let content else { return nil }

        let strippedContent = stripTruncationMarker(from: content)
        let plainContent = stripHTML(from: strippedContent)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !plainContent.isEmpty else { return nil }

        let filteredContent = filterKnownErrorContent(from: plainContent)
        guard let filteredContent else { return nil }

        let formattedText = formatIntoParagraphs(filteredContent)
        var attributedString = AttributedString(formattedText)
        attributedString.font = .system(.body, design: .serif)

        return attributedString
    }

    private nonisolated func createProcessedDescription(from description: String?) -> AttributedString? {
        guard let description else { return nil }

        let cleanText = stripHTML(from: description)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanText.isEmpty else { return nil }

        let formattedText = formatIntoParagraphs(cleanText)

        var attributedString = AttributedString(formattedText)
        attributedString.font = .system(.body, design: .serif, weight: .medium)

        if let firstSentenceEnd = formattedText.firstIndex(where: { $0 == "." || $0 == "!" || $0 == "?" }) {
            let firstSentenceRange = formattedText.startIndex ... firstSentenceEnd
            if let attributedRange = Range(firstSentenceRange, in: attributedString) {
                attributedString[attributedRange].font = .system(.title3, design: .serif, weight: .semibold)
            }
        }

        return attributedString
    }

    private nonisolated func formatIntoParagraphs(_ text: String) -> String {
        let pattern = #"(?<=[.!?])\s+"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }

        let range = NSRange(text.startIndex..., in: text)
        let modifiedText = regex.stringByReplacingMatches(in: text, range: range, withTemplate: "|||")
        let sentences = modifiedText.components(separatedBy: "|||")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard sentences.count > 1 else { return text }

        var paragraphs: [String] = []
        var currentParagraph: [String] = []
        let sentencesPerParagraph = 3

        for sentence in sentences {
            currentParagraph.append(sentence)
            if currentParagraph.count >= sentencesPerParagraph {
                paragraphs.append(currentParagraph.joined(separator: " "))
                currentParagraph = []
            }
        }

        if !currentParagraph.isEmpty {
            paragraphs.append(currentParagraph.joined(separator: " "))
        }

        return paragraphs.joined(separator: "\n\n")
    }

    private nonisolated func stripHTML(from html: String) -> String {
        html.replacingOccurrences(of: #"<[^>]+>"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
    }

    private nonisolated func stripTruncationMarker(from content: String) -> String {
        let pattern = #"\s*\[\+\d+ chars\]"#
        return content.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
    }

    /// Known scraper-injected error phrases from The Guardian and similar sites.
    private nonisolated static let knownErrorPhrases: [String] = [
        "A required part of this site couldn't load.",
        "This may be due to a browser extension, network issues, or browser settings.",
        "Please check your connection, disable any ad blockers, or try a different browser.",
        "Please check your connection, disable any ad blockers",
        "We noticed you're using an ad blocker",
        "Please disable your ad blocker",
        "JavaScript must be enabled",
        "You need to enable JavaScript to run this app",
        "This content is only available with JavaScript",
        "Please enable JavaScript",
        "Your browser does not support JavaScript",
    ]

    /// Filters out known error/noise patterns injected by content scrapers (e.g. go-readability
    /// picking up Guardian anti-adblock banners). Returns the cleaned content, or `nil` if the
    /// entire content is noise and nothing useful remains.
    private nonisolated func filterKnownErrorContent(from content: String) -> String? {
        var cleaned = content

        for phrase in Self.knownErrorPhrases {
            cleaned = cleaned.replacingOccurrences(of: phrase, with: "", options: .caseInsensitive)
        }

        let result = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        return result.isEmpty ? nil : result
    }

    // MARK: - Text-to-Speech

    private func setupTTSBindings() {
        guard let ttsService else { return }

        ttsCancellables.removeAll()
        let generation = ttsGeneration

        ttsService.playbackStatePublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self, self.ttsGeneration == generation else { return }
                self.dispatch(action: .ttsPlaybackStateChanged(state))
                self.syncLiveActivity()
            }
            .store(in: &ttsCancellables)

        ttsService.progressPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                guard let self, self.ttsGeneration == generation else { return }
                self.dispatch(action: .ttsProgressUpdated(progress))
                self.syncLiveActivity()
            }
            .store(in: &ttsCancellables)
    }

    /// Pushes the current TTS state to the active Live Activity, if any.
    /// Calling this when no activity is running is a safe no-op.
    private func syncLiveActivity() {
        let state = currentState
        TTSLiveActivityController.shared.update(
            isPlaying: state.ttsPlaybackState == .playing,
            progress: state.ttsProgress,
            speedLabel: state.ttsSpeedPreset.label
        )
    }

    private func startTTS() {
        guard let ttsService else { return }

        let article = currentState.article
        let text = buildSpeechText(from: article)
        guard !text.isEmpty else { return }

        let language = AppLocalization.shared.language
        let rate = currentState.ttsSpeedPreset.rate

        ttsService.speak(text: text, language: language, rate: rate)
        updateState { $0.isTTSPlayerVisible = true }
        analyticsService?.logEvent(.ttsStarted)

        TTSLiveActivityController.shared.start(
            articleTitle: article.title,
            sourceName: article.source.name,
            speedLabel: currentState.ttsSpeedPreset.label
        )
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
        TTSLiveActivityController.shared.end()
    }

    private func cycleTTSSpeed() {
        let nextPreset = currentState.ttsSpeedPreset.next()
        updateState { state in
            state.ttsSpeedPreset = nextPreset
            state.ttsProgress = 0.0
        }

        // Restart speech with new rate if currently playing
        if currentState.ttsPlaybackState == .playing || currentState.ttsPlaybackState == .paused {
            guard let ttsService else { return }
            let article = currentState.article
            let text = buildSpeechText(from: article)
            guard !text.isEmpty else { return }

            let language = AppLocalization.shared.language
            ttsService.speak(text: text, language: language, rate: nextPreset.rate)

            // Increment generation and re-subscribe so stale callbacks from the
            // old utterance's didCancel are discarded. Re-subscribing to the
            // CurrentValueSubject picks up the current .playing state as baseline.
            ttsGeneration += 1
            setupTTSBindings()
        }

        analyticsService?.logEvent(.ttsSpeedChanged(speed: nextPreset.label))

        TTSLiveActivityController.shared.update(
            isPlaying: currentState.ttsPlaybackState == .playing,
            progress: currentState.ttsProgress,
            speedLabel: nextPreset.label
        )
    }

    private func handleTTSPlaybackStateChanged(_ state: TTSPlaybackState) {
        updateState { $0.ttsPlaybackState = state }

        // Auto-hide player when speech finishes naturally
        if state == .idle, currentState.isTTSPlayerVisible, currentState.ttsProgress >= 1.0 {
            updateState { $0.isTTSPlayerVisible = false }
        }

        if state == .idle {
            TTSLiveActivityController.shared.end()
        }
    }

    private nonisolated func buildSpeechText(from article: Article) -> String {
        var parts: [String] = [article.title]

        if let author = article.author, !author.isEmpty {
            parts.append("By \(author)")
        }

        if let description = article.description {
            let clean = stripHTML(from: description).trimmingCharacters(in: .whitespacesAndNewlines)
            if !clean.isEmpty {
                parts.append(clean)
            }
        }

        if let content = article.content {
            let clean = stripHTML(from: stripTruncationMarker(from: content))
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if let filtered = filterKnownErrorContent(from: clean), !filtered.isEmpty {
                parts.append(filtered)
            }
        }

        return parts.joined(separator: ". ")
    }

    // MARK: - Background Task Management

    /// Safely tracks and auto-removes background tasks with proper cleanup on deinit.
    /// Uses a single MainActor Task to ensure atomic insertion and removal (no race condition).
    private func trackBackgroundTask(_ taskToTrack: Task<Void, Never>) {
        backgroundTasks.insert(taskToTrack)

        Task { @MainActor [weak self] in
            _ = await taskToTrack.result
            self?.backgroundTasks.remove(taskToTrack)
        }
    }

    deinit {
        // Cancel all pending tasks on deallocation
        for task in backgroundTasks {
            task.cancel()
        }
    }

    private func updateState(_ transform: (inout DomainState) -> Void) {
        var state = stateSubject.value
        transform(&state)
        stateSubject.send(state)
    }
}
