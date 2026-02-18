import Combine
import EntropyCore
import Foundation

/// News service that fetches articles from Supabase backend with Guardian API fallback.
///
/// When Supabase is configured, articles are fetched from the RSS aggregator backend
/// which provides high-resolution images and full article content from multiple sources.
/// Falls back to Guardian API when Supabase is not configured or on error.
final class LiveNewsService: APIRequest, NewsService {
    private let useSupabase: Bool

    override init() {
        useSupabase = SupabaseConfig.isConfigured
        super.init()

        if useSupabase {
            Logger.shared.service("LiveNewsService: using Supabase backend", level: .info)
        } else {
            Logger.shared.service("LiveNewsService: Supabase not configured, using Guardian API", level: .warning)
        }
    }

    func fetchTopHeadlines(language: String, country _: String, page: Int) -> AnyPublisher<[Article], Error> {
        if useSupabase {
            return fetchFromSupabase(language: language, page: page)
                .catch { [weak self] error -> AnyPublisher<[Article], Error> in
                    let message = "LiveNewsService: Supabase failed, falling back to Guardian"
                    Logger.shared.service("\(message) - \(error.localizedDescription)", level: .warning)
                    return self?.fetchFromGuardian(page: page)
                        ?? Fail(error: error).eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
        }
        return fetchFromGuardian(page: page)
    }

    func fetchTopHeadlines(
        category: NewsCategory,
        language: String,
        country _: String,
        page: Int
    ) -> AnyPublisher<[Article], Error> {
        if useSupabase {
            return fetchFromSupabase(language: language, category: category, page: page)
                .catch { [weak self] error -> AnyPublisher<[Article], Error> in
                    let message = "LiveNewsService: Supabase category fetch failed"
                    Logger.shared.service("\(message) - \(error.localizedDescription)", level: .warning)
                    return self?.fetchFromGuardian(category: category, page: page)
                        ?? Fail(error: error).eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
        }
        return fetchFromGuardian(category: category, page: page)
    }

    func fetchBreakingNews(language: String, country _: String) -> AnyPublisher<[Article], Error> {
        if useSupabase {
            return fetchBreakingFromSupabase(language: language)
                .catch { [weak self] error -> AnyPublisher<[Article], Error> in
                    let message = "LiveNewsService: Supabase breaking news failed"
                    Logger.shared.service("\(message) - \(error.localizedDescription)", level: .warning)
                    return self?.fetchBreakingFromGuardian()
                        ?? Fail(error: error).eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
        }
        return fetchBreakingFromGuardian()
    }

    func fetchArticle(id: String) -> AnyPublisher<Article, Error> {
        if useSupabase {
            return fetchArticleFromSupabase(id: id)
                .catch { [weak self] error -> AnyPublisher<Article, Error> in
                    let message = "LiveNewsService: Supabase article fetch failed"
                    Logger.shared.service("\(message) - \(error.localizedDescription)", level: .warning)
                    return self?.fetchArticleFromGuardian(id: id)
                        ?? Fail(error: error).eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
        }
        return fetchArticleFromGuardian(id: id)
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

    // MARK: - Guardian Fetchers (Fallback)

    private func fetchFromGuardian(page: Int) -> AnyPublisher<[Article], Error> {
        fetchRequest(
            target: GuardianAPI.search(query: nil, section: nil, page: page, pageSize: 20, orderBy: "newest"),
            dataType: GuardianResponse.self
        )
        .map { response in
            response.response.results.compactMap { $0.toArticle() }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    private func fetchFromGuardian(category: NewsCategory, page: Int) -> AnyPublisher<[Article], Error> {
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
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    private func fetchBreakingFromGuardian() -> AnyPublisher<[Article], Error> {
        fetchRequest(
            target: GuardianAPI.search(query: nil, section: nil, page: 1, pageSize: 5, orderBy: "newest"),
            dataType: GuardianResponse.self
        )
        .map { response in
            response.response.results.compactMap { $0.toArticle() }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    private func fetchArticleFromGuardian(id: String) -> AnyPublisher<Article, Error> {
        fetchRequest(
            target: GuardianAPI.article(id: id),
            dataType: GuardianSingleArticleResponse.self
        )
        .tryMap { response in
            guard response.response.status == "ok" else {
                throw URLError(.badServerResponse)
            }
            guard let article = response.response.content.toArticle() else {
                throw URLError(.cannotParseResponse)
            }
            return article
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
}
