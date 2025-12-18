import Combine
import Foundation
import UIKit

final class ArticleDetailViewModel: ObservableObject {
    @Published var isBookmarked = false
    @Published var showShareSheet = false

    private let article: Article
    private let storageService: StorageService

    init(article: Article, serviceLocator: ServiceLocator) {
        self.article = article
        do {
            storageService = try serviceLocator.retrieve(StorageService.self)
        } catch {
            Logger.shared.service("Failed to retrieve StorageService: \(error)", level: .warning)
            storageService = LiveStorageService()
        }
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
