import Combine
import Foundation

protocol CategoriesService {
    func fetchArticles(for category: NewsCategory, page: Int) -> AnyPublisher<[Article], Error>
}
