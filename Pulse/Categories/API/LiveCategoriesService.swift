import Combine
import EntropyCore
import Foundation

final class LiveCategoriesService: APIRequest, CategoriesService {
    func fetchArticles(for category: NewsCategory, page: Int) -> AnyPublisher<[Article], Error> {
        // NewsAPI free tier has best coverage for US
        let country = "us"

        return fetchRequest(
            target: NewsAPI.topHeadlinesByCategory(category: category, country: country, page: page),
            dataType: NewsResponse.self
        )
        .map { response in
            response.articles.compactMap { $0.toArticle(category: category) }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
}
