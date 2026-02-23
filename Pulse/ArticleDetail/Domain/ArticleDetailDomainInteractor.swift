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

        analyticsService = try? serviceLocator.retrieve(AnalyticsService.self)

        // Start content processing immediately on init
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

        // Optimistic update
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

        let formattedText = formatIntoParagraphs(plainContent)
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

    private func updateState(_ transform: (inout ArticleDetailDomainState) -> Void) {
        var state = stateSubject.value
        transform(&state)
        stateSubject.send(state)
    }
}
