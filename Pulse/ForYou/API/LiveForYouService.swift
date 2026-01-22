import Combine
import EntropyCore
import Foundation

/// For You service that fetches personalized articles from Supabase backend with Guardian API fallback.
///
/// When Supabase is configured, articles are fetched from the RSS aggregator database
/// filtered by user's followed topics. Falls back to Guardian API when Supabase is not configured.
final class LiveForYouService: APIRequest, ForYouService {
    private let storageService: StorageService
    private let useSupabase: Bool

    init(storageService: StorageService) {
        self.storageService = storageService
        useSupabase = SupabaseConfig.isConfigured

        super.init()

        if useSupabase {
            Logger.shared.service("LiveForYouService: using Supabase backend", level: .info)
        } else {
            Logger.shared.service("LiveForYouService: Supabase not configured, using Guardian API", level: .warning)
        }
    }

    func fetchPersonalizedFeed(preferences: UserPreferences, page: Int) -> AnyPublisher<[Article], Error> {
        let topics = preferences.followedTopics

        if useSupabase {
            return fetchFromSupabase(topics: topics, page: page, preferences: preferences)
                .catch { [weak self] error -> AnyPublisher<[Article], Error> in
                    Logger.shared.service("LiveForYouService: Supabase failed, falling back to Guardian - \(error.localizedDescription)", level: .warning)
                    return self?.fetchFromGuardian(topics: topics, page: page, preferences: preferences) ?? Fail(error: error).eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
        }
        return fetchFromGuardian(topics: topics, page: page, preferences: preferences)
    }

    // MARK: - Supabase Fetchers

    private func fetchFromSupabase(topics: [NewsCategory], page: Int, preferences: UserPreferences) -> AnyPublisher<[Article], Error> {
        if topics.isEmpty {
            return fetchAllFromSupabase(page: page, preferences: preferences)
        }

        let publishers = topics.map { category in
            fetchRequest(
                target: SupabaseAPI.articlesByCategory(category: category.rawValue, page: page, pageSize: 20),
                dataType: [SupabaseArticle].self
            )
            .map { $0.map { $0.toArticle() } }
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
            .handleEvents(receiveOutput: { articles in
                Logger.shared.service("LiveForYouService: Supabase returned \(articles.count) personalized articles", level: .debug)
            })
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    private func fetchAllFromSupabase(page: Int, preferences: UserPreferences) -> AnyPublisher<[Article], Error> {
        fetchRequest(
            target: SupabaseAPI.articles(page: page, pageSize: 20),
            dataType: [SupabaseArticle].self
        )
        .map { $0.map { $0.toArticle() } }
        .map { [preferences] articles in
            self.filterMutedContent(articles, preferences: preferences)
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    // MARK: - Guardian Fetchers (Fallback)

    private func fetchFromGuardian(topics: [NewsCategory], page: Int, preferences: UserPreferences) -> AnyPublisher<[Article], Error> {
        if topics.isEmpty {
            return fetchAllFromGuardian(page: page, preferences: preferences)
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

    private func fetchAllFromGuardian(page: Int, preferences: UserPreferences) -> AnyPublisher<[Article], Error> {
        fetchRequest(
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

    // MARK: - Helpers

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
