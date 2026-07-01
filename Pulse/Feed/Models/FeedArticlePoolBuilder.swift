import Combine
import EntropyCore
import Foundation

/// Builds the candidate article pool for digest generation — the top 10
/// articles from each `NewsCategory`, fetched in parallel and flattened.
///
/// Shared by `FeedDomainInteractor.fetchLatestNews()` (the interactive Feed
/// tab load) and `MorningBriefingPrefetcher` (opportunistic background
/// pre-generation), so the fetch-and-flatten logic exists in exactly one
/// place.
enum FeedArticlePoolBuilder {
    /// Fetches the top 10 articles from each `NewsCategory` in parallel and
    /// returns them flattened, sorted by `publishedAt` (most recent first).
    /// A category that fails to fetch contributes no articles rather than
    /// failing the whole pool.
    static func fetchPool(newsService: NewsService) async -> [Article] {
        let service = UncheckedSendableBox(value: newsService)
        var allArticles: [Article] = []

        await withTaskGroup(of: [Article].self) { group in
            for category in NewsCategory.allCases {
                group.addTask {
                    do {
                        let articles = try await withCheckedThrowingContinuation { continuation in
                            var cancellable: AnyCancellable?
                            cancellable = service.value
                                .fetchTopHeadlines(category: category, language: "en", country: "us", page: 1)
                                .first()
                                .sink(
                                    receiveCompletion: { completion in
                                        if case let .failure(error) = completion {
                                            continuation.resume(throwing: error)
                                        }
                                        cancellable?.cancel()
                                    },
                                    receiveValue: { articles in
                                        continuation.resume(returning: articles)
                                    }
                                )
                        }
                        return Array(articles.prefix(10))
                    } catch {
                        Logger.shared.warning(
                            "Failed to fetch \(category.displayName): \(error)",
                            category: "FeedArticlePoolBuilder"
                        )
                        return []
                    }
                }
            }

            for await articles in group {
                guard !Task.isCancelled else { return }
                allArticles.append(contentsOf: articles)
            }
        }

        allArticles.sort { $0.publishedAt > $1.publishedAt }
        return allArticles
    }
}
