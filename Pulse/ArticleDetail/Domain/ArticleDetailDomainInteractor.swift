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
    private let newsService: NewsService?
    private let playbackQueueService: PlaybackQueueService?
    private let analyticsService: AnalyticsService?
    private let engagementEventsService: EngagementEventsService?
    private let stateSubject: CurrentValueSubject<DomainState, Never>
    private var cancellables = Set<AnyCancellable>()
    private var backgroundTasks = Set<Task<Void, Never>>()

    /// Once we've scheduled the 30-second read-engagement capture for this
    /// article view, don't reschedule even if `onAppear` fires twice.
    private var hasScheduledRead30sCapture = false

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
            storageService = LiveStorageService(enableCloudKit: false)
        }

        newsService = try? serviceLocator.retrieve(NewsService.self)
        playbackQueueService = try? serviceLocator.retrieve(PlaybackQueueService.self)
        analyticsService = try? serviceLocator.retrieve(AnalyticsService.self)
        engagementEventsService = try? serviceLocator.retrieve(EngagementEventsService.self)

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
            recordEngagement(kind: .shared)
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
        case .listen:
            listen()

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

        scheduleRead30sCapture()
    }

    // MARK: - Engagement Capture

    /// Schedules a deferred capture that records a `.read30s` engagement
    /// event after the user has had the article open for 30 seconds. The
    /// task lives in `backgroundTasks` and is cancelled on `deinit`, so
    /// closing the article before the threshold elapses produces no signal.
    private func scheduleRead30sCapture() {
        guard !hasScheduledRead30sCapture, let engagementEventsService else { return }
        hasScheduledRead30sCapture = true

        let event = EngagementEvent(from: currentState.article, kind: .read30s)
        let service = UncheckedSendableBox(value: engagementEventsService)
        let task = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: 30 * 1_000_000_000)
            } catch {
                return
            }
            guard self != nil, !Task.isCancelled else { return }
            await service.value.record(event)
        }
        trackBackgroundTask(task)
    }

    /// Records an immediate engagement event (`.bookmarked`, `.shared`, …)
    /// for the current article. No-op when the engagement service isn't
    /// registered (e.g. preview locator).
    private func recordEngagement(kind: EngagementEvent.Kind) {
        guard let engagementEventsService else { return }
        let event = EngagementEvent(from: currentState.article, kind: kind)
        let service = UncheckedSendableBox(value: engagementEventsService)
        let task = Task { [weak self] in
            guard self != nil else { return }
            await service.value.record(event)
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

        if !wasBookmarked {
            recordEngagement(kind: .bookmarked)
        }

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
                            .prefix(5),
                    )
                    self?.dispatch(action: .relatedArticlesLoaded(related))
                },
            )
            .store(in: &cancellables)
    }

    // MARK: - Browser

    private func openInBrowser() {
        guard let url = Self.externalURL(from: currentState.article.url) else { return }
        UIApplication.shared.open(url)
    }

    /// HTTPS-only gate. An attacker-controlled article row could redirect
    /// users through a plaintext page on a hostile network; the article URL
    /// originates from RSS feeds we don't fully control. Delegates to the
    /// shared `SafeMediaURL` gate so the inline-video, audio, and browser sinks
    /// can't drift apart. Static so it's unit-testable without `UIApplication`.
    static func externalURL(from urlString: String) -> URL? {
        SafeMediaURL.validated(urlString)
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

    // Text cleaning is shared with the playback queue's narration path via
    // `SpeechTextBuilder` so display and speech can never drift apart.

    private nonisolated func stripHTML(from html: String) -> String {
        SpeechTextBuilder.stripHTML(from: html)
    }

    private nonisolated func stripTruncationMarker(from content: String) -> String {
        SpeechTextBuilder.stripTruncationMarker(from: content)
    }

    private nonisolated func filterKnownErrorContent(from content: String) -> String? {
        SpeechTextBuilder.filterKnownErrorContent(from: content)
    }

    // MARK: - Text-to-Speech

    /// Hands the article to the global playback queue as a single-item
    /// session, replacing whatever is playing. The mini player (mounted in
    /// `CoordinatorView`) renders all transport controls, and playback —
    /// including the Live Activity and Now Playing entry — is owned by
    /// `PlaybackQueueService`, so it survives navigating away from here.
    private func listen() {
        guard let playbackQueueService else { return }

        let item = PlaybackItem.article(currentState.article, language: AppLocalization.shared.language)
        guard !item.speechText.isEmpty else { return }

        playbackQueueService.play(items: [item], mode: .singleArticle)
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
        // Cancel all pending tasks on deallocation. Playback is deliberately
        // NOT stopped here: it belongs to the global `PlaybackQueueService`
        // and must survive this screen being torn down.
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
