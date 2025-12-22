import Combine
import Foundation
import UIKit

final class ArticleDetailViewModel: ObservableObject {
    enum ProcessedContent: Equatable {
        case html(String)
        case plain(String)
    }

    @Published var isBookmarked = false
    @Published var showShareSheet = false
    @Published var isContentExpanded = false
    @Published private(set) var processedContent: ProcessedContent?
    @Published private(set) var isContentTruncated = false

    private let article: Article
    private let storageService: StorageService
    let contentLineLimit = 4

    init(article: Article, serviceLocator: ServiceLocator) {
        self.article = article
        do {
            storageService = try serviceLocator.retrieve(StorageService.self)
        } catch {
            Logger.shared.service("Failed to retrieve StorageService: \(error)", level: .warning)
            storageService = LiveStorageService()
        }
        processContent()
    }

    private func processContent() {
        guard let content = article.content else {
            processedContent = nil
            return
        }

        let strippedContent = stripTruncationMarker(from: content)

        if containsHTML(in: content) {
            processedContent = .html(strippedContent)
            isContentTruncated = false
        } else {
            let sanitizedContent = plainText(from: strippedContent)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !sanitizedContent.isEmpty else {
                processedContent = nil
                return
            }
            processedContent = .plain(sanitizedContent)
            isContentTruncated = content.range(of: #"\[\+\d+ chars\]"#, options: .regularExpression) != nil
        }
    }

    func toggleContentExpansion() {
        isContentExpanded.toggle()
    }

    private func plainText(from html: String) -> String {
        guard let data = html.data(using: .utf8) else { return html }
        if let attributedString = try? NSAttributedString(
            data: data,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue,
            ],
            documentAttributes: nil
        ) {
            return attributedString.string
        }
        return html
    }

    private func stripTruncationMarker(from content: String) -> String {
        let pattern = #"\s*\[\+\d+ chars\]"#
        return content.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
    }

    private func containsHTML(in content: String) -> Bool {
        content.range(of: #"<[^>]+>"#, options: .regularExpression) != nil
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
