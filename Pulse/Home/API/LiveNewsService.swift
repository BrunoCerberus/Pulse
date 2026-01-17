import Combine
import EntropyCore
import Foundation

final class LiveNewsService: APIRequest, NewsService {
    func fetchTopHeadlines(country _: String, page: Int) -> AnyPublisher<[Article], Error> {
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

    func fetchTopHeadlines(category: NewsCategory, country _: String, page: Int) -> AnyPublisher<[Article], Error> {
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

    func fetchBreakingNews(country _: String) -> AnyPublisher<[Article], Error> {
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

    func fetchArticle(id: String) -> AnyPublisher<Article, Error> {
        fetchRequest(
            target: GuardianAPI.article(id: id),
            dataType: GuardianSingleArticleResponse.self
        )
        .tryMap { response in
            guard let article = response.response.content.toArticle() else {
                throw URLError(.cannotParseResponse)
            }
            return article
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
}
