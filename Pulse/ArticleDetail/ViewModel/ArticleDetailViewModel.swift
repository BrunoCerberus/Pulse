import Combine
import Foundation
import UIKit

final class ArticleDetailViewModel: ObservableObject {
    @Published var isBookmarked = false
    @Published var showShareSheet = false
    @Published var isContentExpanded = false
    @Published private(set) var processedContent: String?
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

        isContentTruncated = content.range(of: #"\[\+\d+ chars\]"#, options: .regularExpression) != nil
        let strippedContent = stripTruncationMarker(from: content)
        let plainContent = stripHTML(from: strippedContent)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !plainContent.isEmpty else {
            processedContent = nil
            return
        }

        processedContent = plainContent
    }

    func toggleContentExpansion() {
        isContentExpanded.toggle()
    }

    private func stripHTML(from html: String) -> String {
        html.replacingOccurrences(of: #"<[^>]+>"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
    }

    private func stripTruncationMarker(from content: String) -> String {
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
