import Combine
import EntropyCore
import Foundation

final class LiveNewsService: APIRequest, NewsService {
    func fetchTopHeadlines(country: String, page: Int) -> AnyPublisher<[Article], Error> {
        fetchRequest(target: NewsAPI.topHeadlines(country: country, page: page), dataType: NewsResponse.self)
            .map { response in
                response.articles.compactMap { $0.toArticle() }
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func fetchTopHeadlines(category: NewsCategory, country: String, page: Int) -> AnyPublisher<[Article], Error> {
        fetchRequest(
            target: NewsAPI.topHeadlinesByCategory(category: category, country: country, page: page),
            dataType: NewsResponse.self
        )
        .map { response in
            response.articles.compactMap { $0.toArticle(category: category) }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func fetchBreakingNews(country: String) -> AnyPublisher<[Article], Error> {
        fetchRequest(target: NewsAPI.topHeadlines(country: country, page: 1), dataType: NewsResponse.self)
            .map { response in
                Array(response.articles.prefix(5).compactMap { $0.toArticle() })
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
