import Combine
import Foundation

protocol NewsService {
    func fetchTopHeadlines(country: String, page: Int) -> AnyPublisher<[Article], Error>
    func fetchTopHeadlines(category: NewsCategory, country: String, page: Int) -> AnyPublisher<[Article], Error>
    func fetchBreakingNews(country: String) -> AnyPublisher<[Article], Error>
    func fetchArticle(id: String) -> AnyPublisher<Article, Error>
}
