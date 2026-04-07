import Combine
import EntropyCore
import Foundation

/// News service that fetches articles from the Supabase backend.
///
/// Articles are fetched from the RSS aggregator backend which provides
/// high-resolution images and full article content from multiple sources.
final class LiveNewsService: APIRequest, NewsService {
    override init() {
        super.init()

        guard SupabaseConfig.isConfigured else {
            Logger.shared.service("LiveNewsService: Supabase not configured", level: .error)
            return
        }
        Logger.shared.service("LiveNewsService: using Supabase backend", level: .info)
    }

    func fetchTopHeadlines(language: String, country _: String, page: Int) -> AnyPublisher<[Article], Error> {
        fetchFromSupabase(language: language, page: page)
    }

    func fetchTopHeadlines(
        category: NewsCategory,
        language: String,
        country _: String,
        page: Int
    ) -> AnyPublisher<[Article], Error> {
        fetchFromSupabase(language: language, category: category, page: page)
    }

    func fetchBreakingNews(language: String, country _: String) -> AnyPublisher<[Article], Error> {
        fetchBreakingFromSupabase(language: language)
    }

    func fetchArticle(id: String) -> AnyPublisher<Article, Error> {
        fetchArticleFromSupabase(id: id)
    }

    // MARK: - Supabase Fetchers

    private func fetchFromSupabase(language: String, page: Int) -> AnyPublisher<[Article], Error> {
        fetchRequest(
            target: SupabaseAPI.articles(language: language, page: page, pageSize: 20),
            dataType: [SupabaseArticle].self
        )
        .map { $0.map { $0.toArticle() } }
        .handleEvents(receiveOutput: { articles in
            Logger.shared.service("LiveNewsService: Supabase returned \(articles.count) articles", level: .debug)
        })
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    private func fetchFromSupabase(
        language: String,
        category: NewsCategory,
        page: Int
    ) -> AnyPublisher<[Article], Error> {
        fetchRequest(
            target: SupabaseAPI.articlesByCategory(
                language: language,
                category: category.rawValue,
                page: page,
                pageSize: 20
            ),
            dataType: [SupabaseArticle].self
        )
        .map { $0.map { $0.toArticle() } }
        .handleEvents(receiveOutput: { articles in
            let count = articles.count
            let cat = category.rawValue
            Logger.shared.service("LiveNewsService: Supabase returned \(count) for \(cat)", level: .debug)
        })
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    private func fetchBreakingFromSupabase(language: String) -> AnyPublisher<[Article], Error> {
        fetchRequest(
            target: SupabaseAPI.breakingNews(language: language, limit: 10),
            dataType: [SupabaseArticle].self
        )
        .map { $0.map { $0.toArticle() } }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    private func fetchArticleFromSupabase(id: String) -> AnyPublisher<Article, Error> {
        fetchRequest(
            target: SupabaseAPI.article(id: id),
            dataType: [SupabaseArticle].self
        )
        .tryMap { response in
            guard let article = response.first else {
                throw URLError(.resourceUnavailable)
            }
            return article.toArticle()
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
}
