import Combine
import EntropyCore
import Foundation

/// Live implementation of DigestService that fetches fresh news from Guardian API
final class LiveDigestService: APIRequest, DigestService {
    private let storageService: StorageService
    private var cancellables = Set<AnyCancellable>()

    init(storageService: StorageService) {
        self.storageService = storageService
    }

    func fetchFreshNews(for topics: [NewsCategory]) async throws -> [Article] {
        guard !topics.isEmpty else {
            return []
        }

        // Fetch articles for each topic in parallel
        let articles = try await withThrowingTaskGroup(of: [Article].self) { group in
            for topic in topics {
                group.addTask {
                    try await self.fetchArticlesForTopic(topic)
                }
            }

            var allArticles: [Article] = []
            for try await topicArticles in group {
                allArticles.append(contentsOf: topicArticles)
            }
            return allArticles
        }

        // Deduplicate and sort by date
        let uniqueArticles = Dictionary(grouping: articles, by: { $0.id })
            .compactMapValues { $0.first }
            .values
            .sorted { $0.publishedAt > $1.publishedAt }

        // Apply muting filters
        let preferences = try await storageService.fetchUserPreferences() ?? .default
        return filterMutedContent(Array(uniqueArticles), preferences: preferences)
    }

    private func fetchArticlesForTopic(_ topic: NewsCategory) async throws -> [Article] {
        try await withCheckedThrowingContinuation { continuation in
            fetchRequest(
                target: GuardianAPI.search(
                    query: nil,
                    section: topic.guardianSection,
                    page: 1,
                    pageSize: 10,
                    orderBy: "newest"
                ),
                dataType: GuardianResponse.self
            )
            .map { response in
                response.response.results.compactMap { $0.toArticle(category: topic) }
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        continuation.resume(throwing: error)
                    }
                },
                receiveValue: { articles in
                    continuation.resume(returning: articles)
                }
            )
            .store(in: &cancellables)
        }
    }

    private func filterMutedContent(_ articles: [Article], preferences: UserPreferences) -> [Article] {
        articles.filter { article in
            let isMutedSource = preferences.mutedSources.contains(article.source.name)
            let containsMutedKeyword = preferences.mutedKeywords.contains { keyword in
                article.title.lowercased().contains(keyword.lowercased()) ||
                    (article.description?.lowercased().contains(keyword.lowercased()) ?? false)
            }
            return !isMutedSource && !containsMutedKeyword
        }
    }
}
