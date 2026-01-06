import Combine
import Foundation
import UIKit

@MainActor
final class ArticleDetailViewModel: ObservableObject {
    @Published var isBookmarked = false
    @Published var showShareSheet = false
    @Published private(set) var processedContent: AttributedString?
    @Published private(set) var processedDescription: AttributedString?
    @Published private(set) var isProcessingContent = true

    private let article: Article
    private let storageService: StorageService
    private var processingTask: Task<Void, Never>?

    init(article: Article, serviceLocator: ServiceLocator) {
        self.article = article
        do {
            storageService = try serviceLocator.retrieve(StorageService.self)
        } catch {
            Logger.shared.service("Failed to retrieve StorageService: \(error)", level: .warning)
            storageService = LiveStorageService()
        }
        startContentProcessing()
    }

    deinit {
        processingTask?.cancel()
    }

    private func startContentProcessing() {
        processingTask = Task { [weak self] in
            guard let self else { return }

            let article = self.article

            // Process content on background thread
            let content = await Task.detached(priority: .userInitiated) {
                self.createProcessedContent(from: article.content)
            }.value

            let description = await Task.detached(priority: .userInitiated) {
                self.createProcessedDescription(from: article.description)
            }.value

            guard !Task.isCancelled else { return }

            await MainActor.run {
                self.processedContent = content
                self.processedDescription = description
                self.isProcessingContent = false
            }
        }
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
        // Split into sentences using regex pattern for sentence boundaries
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

    func onAppear() {
        Task {
            await saveToReadingHistory()
            await checkBookmarkStatus()
        }
    }

    func toggleBookmark() {
        Task { @MainActor in
            if isBookmarked {
                try? await storageService.deleteArticle(article)
            } else {
                try? await storageService.saveArticle(article)
            }
            isBookmarked.toggle()
        }
    }

    func share() {
        showShareSheet = true
    }

    func openInBrowser() {
        guard let url = URL(string: article.url) else { return }
        UIApplication.shared.open(url)
    }

    private func saveToReadingHistory() async {
        try? await storageService.saveReadingHistory(article)
    }

    private func checkBookmarkStatus() async {
        let bookmarked = await storageService.isBookmarked(article.id)
        await MainActor.run {
            isBookmarked = bookmarked
        }
    }
}
