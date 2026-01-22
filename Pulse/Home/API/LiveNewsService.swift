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

    func fetchTopHeadlines(country _: String, page: Int) -> AnyPublisher<[Article], Error> {
        if useSupabase {
            return fetchFromSupabase(page: page)
                .catch { [weak self] error -> AnyPublisher<[Article], Error> in
                    Logger.shared.service("LiveNewsService: Supabase failed, falling back to Guardian - \(error.localizedDescription)", level: .warning)
                    return self?.fetchFromGuardian(page: page) ?? Fail(error: error).eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
        }
        return fetchFromGuardian(page: page)
    }

    func fetchTopHeadlines(category: NewsCategory, country _: String, page: Int) -> AnyPublisher<[Article], Error> {
        if useSupabase {
            return fetchFromSupabase(category: category, page: page)
                .catch { [weak self] error -> AnyPublisher<[Article], Error> in
                    Logger.shared.service("LiveNewsService: Supabase category fetch failed, falling back to Guardian - \(error.localizedDescription)", level: .warning)
                    return self?.fetchFromGuardian(category: category, page: page) ?? Fail(error: error).eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
        }
        return fetchFromGuardian(category: category, page: page)
    }

    func fetchBreakingNews(country _: String) -> AnyPublisher<[Article], Error> {
        if useSupabase {
            return fetchBreakingFromSupabase()
                .catch { [weak self] error -> AnyPublisher<[Article], Error> in
                    Logger.shared.service("LiveNewsService: Supabase breaking news failed, falling back to Guardian - \(error.localizedDescription)", level: .warning)
                    return self?.fetchBreakingFromGuardian() ?? Fail(error: error).eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
        }
        return fetchBreakingFromGuardian()
    }

    func fetchArticle(id: String) -> AnyPublisher<Article, Error> {
        if useSupabase {
            return fetchArticleFromSupabase(id: id)
                .catch { [weak self] error -> AnyPublisher<Article, Error> in
                    Logger.shared.service("LiveNewsService: Supabase article fetch failed, falling back to Guardian - \(error.localizedDescription)", level: .warning)
                    return self?.fetchArticleFromGuardian(id: id) ?? Fail(error: error).eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
        }
        return fetchArticleFromGuardian(id: id)
    }

    // MARK: - Supabase Fetchers

    private func fetchFromSupabase(page: Int) -> AnyPublisher<[Article], Error> {
        fetchRequest(
            target: SupabaseAPI.articles(page: page, pageSize: 20),
            dataType: [SupabaseArticle].self
        )
        .map { $0.map { $0.toArticle() } }
        .handleEvents(receiveOutput: { articles in
            Logger.shared.service("LiveNewsService: Supabase returned \(articles.count) articles", level: .debug)
        })
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    private func fetchFromSupabase(category: NewsCategory, page: Int) -> AnyPublisher<[Article], Error> {
        fetchRequest(
            target: SupabaseAPI.articlesByCategory(category: category.rawValue, page: page, pageSize: 20),
            dataType: [SupabaseArticle].self
        )
        .map { $0.map { $0.toArticle() } }
        .handleEvents(receiveOutput: { articles in
            Logger.shared.service("LiveNewsService: Supabase returned \(articles.count) articles for \(category.rawValue)", level: .debug)
        })
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    private func fetchBreakingFromSupabase() -> AnyPublisher<[Article], Error> {
        let oneDayAgo = ISO8601DateFormatter().string(from: Date().addingTimeInterval(-86400))
        return fetchRequest(
            target: SupabaseAPI.breakingNews(since: oneDayAgo),
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
