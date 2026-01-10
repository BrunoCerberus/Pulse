import Combine
import Foundation
import UIKit

final class ArticleDetailDomainInteractor: CombineInteractor {
    typealias DomainState = ArticleDetailDomainState
    typealias DomainAction = ArticleDetailDomainAction

    private let storageService: StorageService
    private let summarizationService: SummarizationService
    private let stateSubject: CurrentValueSubject<ArticleDetailDomainState, Never>
    private var cancellables = Set<AnyCancellable>()
    private var backgroundTasks = Set<Task<Void, Never>>()
    private var summarizationTask: Task<Void, Never>?

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

        do {
            summarizationService = try serviceLocator.retrieve(SummarizationService.self)
        } catch {
            Logger.shared.service("Failed to retrieve SummarizationService: \(error)", level: .warning)
            summarizationService = LiveSummarizationService()
        }

        setupBindings()
        // Start content processing immediately on init
        startContentProcessing()
    }

    private func setupBindings() {
        summarizationService.modelStatusPublisher
            .sink { [weak self] status in
                self?.dispatch(action: .modelStatusChanged(status))
            }
            .store(in: &cancellables)
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
            cancelSummarization()
            updateState { state in
                state.showSummarizationSheet = false
                state.summarizationState = .idle
                state.generatedSummary = ""
            }
        case .startSummarization:
            startSummarization()
        case .cancelSummarization:
            cancelSummarization()
        case let .summarizationStateChanged(newState):
            updateState { $0.summarizationState = newState }
        case let .summarizationTokenReceived(token):
            updateState { $0.generatedSummary += token }
        case let .modelStatusChanged(status):
            updateState { state in
                state.modelStatus = status
                if case let .loading(progress) = status,
                   case .loadingModel = state.summarizationState
                {
                    state.summarizationState = .loadingModel(progress: progress)
                } else if case let .error(message) = status {
                    state.summarizationState = .error(message)
                }
            }
        }
    }

    // MARK: - Lifecycle

    private func onAppear() {
        saveToReadingHistory()
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

    private func saveToReadingHistory() {
        let article = currentState.article
        let task = Task { [weak self] in
            guard let self else { return }
            try? await storageService.saveReadingHistory(article)
        }
        trackBackgroundTask(task)
    }

    // MARK: - Browser

    private func openInBrowser() {
        guard let url = URL(string: currentState.article.url) else { return }
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

    // MARK: - Summarization

    private func startSummarization() {
        summarizationTask?.cancel()
        updateState { state in
            state.generatedSummary = ""
            state.summarizationState = .loadingModel(progress: 0)
        }

        summarizationTask = Task { [weak self] in
            guard let self else { return }

            do {
                // loadModelIfNeeded is idempotent and handles concurrent calls
                try await summarizationService.loadModelIfNeeded()

                guard !Task.isCancelled else { return }

                await MainActor.run { [weak self] in
                    self?.dispatch(action: .summarizationStateChanged(.generating))
                }

                var fullText = ""
                var tokensSinceLastUpdate = 0
                let updateBatchSize = 3

                for try await token in summarizationService.summarize(article: currentState.article) {
                    guard !Task.isCancelled else { break }

                    fullText += token
                    tokensSinceLastUpdate += 1

                    if tokensSinceLastUpdate >= updateBatchSize {
                        let currentText = cleanLLMOutput(fullText)
                        await MainActor.run { [weak self] in
                            self?.updateState { $0.generatedSummary = currentText }
                        }
                        tokensSinceLastUpdate = 0
                    }
                }

                guard !Task.isCancelled else { return }

                let finalSummary = cleanLLMOutput(fullText)
                await MainActor.run { [weak self] in
                    self?.updateState { state in
                        state.generatedSummary = finalSummary
                        state.summarizationState = finalSummary.isEmpty ? .error("No summary generated") : .completed
                    }
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run { [weak self] in
                    self?.dispatch(action: .summarizationStateChanged(.error(error.localizedDescription)))
                }
            }
        }
    }

    private func cancelSummarization() {
        summarizationTask?.cancel()
        summarizationService.cancelSummarization()
        updateState { state in
            state.summarizationState = .idle
            state.generatedSummary = ""
        }
    }

    private nonisolated func cleanLLMOutput(_ text: String) -> String {
        var cleaned = text

        // Remove chat template markers
        let markers = [
            "<|system|>", "<|user|>", "<|assistant|>", "<|end|>",
            "</s>", "<s>", "<|eot_id|>", "<|start_header_id|>", "<|end_header_id|>",
        ]
        for marker in markers {
            cleaned = cleaned.replacingOccurrences(of: marker, with: "")
        }

        // Remove common instruction artifacts (case-insensitive, at start)
        let prefixes = ["here's the summary:", "here is the summary:", "summary:"]
        let lowercased = cleaned.lowercased()
        for prefix in prefixes {
            if lowercased.hasPrefix(prefix) {
                cleaned = String(cleaned.dropFirst(prefix.count))
                break
            }
        }

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Background Task Management

    private func trackBackgroundTask(_ task: Task<Void, Never>) {
        backgroundTasks.insert(task)
        Task { [weak self] in
            guard let self else { return }
            await task.value
            backgroundTasks.remove(task)
        }
    }

    deinit {
        backgroundTasks.forEach { $0.cancel() }
        summarizationTask?.cancel()
    }

    private func updateState(_ transform: (inout ArticleDetailDomainState) -> Void) {
        var state = stateSubject.value
        transform(&state)
        stateSubject.send(state)
    }
}
