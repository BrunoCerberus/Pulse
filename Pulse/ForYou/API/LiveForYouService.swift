import Combine
import EntropyCore
import Foundation

final class LiveForYouService: APIRequest, ForYouService {
    private let storageService: StorageService

    init(storageService: StorageService) {
        self.storageService = storageService
    }

    func fetchPersonalizedFeed(preferences: UserPreferences, page: Int) -> AnyPublisher<[Article], Error> {
        let topics = preferences.followedTopics

        if topics.isEmpty {
            return fetchRequest(
                target: GuardianAPI.search(query: nil, section: nil, page: page, pageSize: 20, orderBy: "newest"),
                dataType: GuardianResponse.self
            )
            .map { response in
                response.response.results.compactMap { $0.toArticle() }
            }
            .map { [preferences] articles in
                self.filterMutedContent(articles, preferences: preferences)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
        }

        let publishers = topics.map { category in
            fetchRequest(
                target: GuardianAPI.search(
                    query: nil,
                    section: category.guardianSection,
                    page: page,
                    pageSize: 20,
                    orderBy: "newest"
                ),
                dataType: GuardianResponse.self
            )
            .map { response in
                response.response.results.compactMap { $0.toArticle(category: category) }
            }
            .catch { _ in Just([Article]()).setFailureType(to: Error.self) }
            .eraseToAnyPublisher()
        }

        return Publishers.MergeMany(publishers)
            .collect()
            .map { articleArrays in
                let allArticles = articleArrays.flatMap { $0 }
                let uniqueArticles = Dictionary(grouping: allArticles, by: { $0.id })
                    .compactMapValues { $0.first }
                    .values
                    .sorted { $0.publishedAt > $1.publishedAt }
                return Array(uniqueArticles)
            }
            .map { [preferences] articles in
                self.filterMutedContent(articles, preferences: preferences)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
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
